# frozen_string_literal: true

require "rails_helper"
require_relative "../fabricators/webinar_fabricator.rb"

describe Zoom::WebhooksController do
  let!(:zoom_id) { "1234" }
  let(:verification_payload) do
    {
      payload: {
        account_id: "KlLYq9UvR3Cv5pcCVlQuNw",
        object: {
          uuid: "QOOZqdxqRVuyailQGyJHwA==",
          participant: {
            user_id: "16778240",
            user_name: "Juan David Martínez Cubillos",
            registrant_id: "E5qMfcA4SSmHgDMVSwYong",
            participant_user_id: "E5qMfcA4SSmHgDMVSwYong",
            id: "E5qMfcA4SSmHgDMVSwYong",
            join_time: "2023-07-07T17:59:30Z",
            email: "juan@discourse.org",
            participant_uuid: "027419D6-2E3C-2861-BCCD-B4F67D41C260",
          },
          id: "96766811781",
          type: 5,
          topic: "Join test",
          host_id: "E5qMfcA4SSmHgDMVSwYong",
          duration: 300,
          start_time: "2023-07-07T17:59:30Z",
          timezone: "America/Bogota",
        },
      },
      event_ts: 1_688_752_773_282,
      event: "webinar.participant_joined",
    }
  end

  describe "mismatched zoom authorization token" do
    before { SiteSetting.zoom_webhooks_secret_token = "" }
    it "errors for webinar_registration_created" do
      post "/zoom/webhooks/webinars.json",
           params: {
             webhook: webinar_updated,
           },
           headers: {
             "x-zm-signature": "not-valid",
           }
      expect(response.status).to eq(403)
      expect(response.body).to include("invalid_access")
    end
  end

  describe "valid zoom authorization token" do
    before { SiteSetting.zoom_webhooks_secret_token = "not_a_secret" }
    it "webinar_registration_created" do
      post "/zoom/webhooks/webinars.json",
           params: {
             webhook: verification_payload,
           },
           headers: {
             "x-zm-signature":
               "v0=fd4949fedcf7a962918e7c541469383a3ec597a6d5e3a026907f16922e25cb67",
             "x-zm-request-timestamp": "1688752773",
           }
      expect(response.status).to eq(200)
    end
  end

  describe "authorized webhooks" do
    fab!(:topic) { Fabricate(:topic) }
    fab!(:webinar) { Fabricate(:webinar, topic: topic, zoom_id: 123, duration: 60) }
    let!(:webhooks_secret_token) { "15123" }

    before do
      SiteSetting.zoom_webhooks_secret_token = webhooks_secret_token
      described_class.any_instance.stubs(:ensure_webhook_authenticity).returns(true)
    end

    describe "#webinar_started" do
      it "updates webinar status when it starts" do
        post "/zoom/webhooks/webinars.json", params: { webhook: webinar_started(zoom_id: 123) }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.status).to eq("started")
      end
    end

    describe "#webinar_updated" do
      it "updates starts_at and ends_at when start_time changes" do
        start_time = 1.week.ago
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook: webinar_updated(zoom_id: 123, start_time: start_time),
             }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.starts_at).to be_within_one_second_of(start_time)
        expect(webinar.ends_at).to be_within_one_second_of(start_time + 60.minutes)
      end

      it "updates ends_at when duration changes" do
        duration = 120
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook: webinar_updated(zoom_id: 123, duration: duration),
             }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.duration).to eq(duration)
        expect(webinar.ends_at).to eq_time(webinar.starts_at + duration.minutes)
      end

      it "updates starts_at and ends_at when start_time and duration change" do
        start_time = 1.week.ago
        duration = 180
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook: webinar_updated(zoom_id: 123, start_time: start_time, duration: duration),
             }
        expect(response.status).to eq(200)
        webinar.reload

        expect(webinar.starts_at).to be_within_one_second_of(start_time)
        expect(webinar.duration).to eq(duration)
        expect(webinar.ends_at).to be_within_one_second_of(webinar.starts_at + duration.minutes)
      end

      it "updates settings" do
        approval_type = 0
        enforce_login = true
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook:
                 webinar_updated(
                   zoom_id: 123,
                   approval_type: approval_type,
                   enforce_login: enforce_login,
                 ),
             }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.approval_type).to eq(Webinar.approval_types.key(approval_type))
        expect(webinar.enforce_login).to eq(enforce_login)
      end
    end

    describe "#webinar_participant_joined" do
      it "fires a DiscourseEvent" do
        DiscourseEvent
          .expects(:trigger)
          .with() { |value| value === :webinar_participant_joined }
          .once
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook: webinar_participant_joined(webinar_id: 123),
             }
      end
    end

    describe "#webinar_participant_left" do
      it "fires a DiscourseEvent" do
        DiscourseEvent.expects(:trigger).with() { |value| value === :webinar_participant_left }.once
        post "/zoom/webhooks/webinars.json",
             params: {
               webhook: webinar_participant_left(webinar_id: 123),
             }
      end
    end
  end
end

def webinar_updated(args = {})
  old_object = { id: args[:zoom_id] }
  object = { id: args[:zoom_id], settings: {} }

  object.merge!(start_time: args[:start_time]) unless args[:start_time].nil?

  object.merge!(duration: args[:duration]) unless args[:duration].nil?

  object[:settings].merge!(approval_type: args[:approval_type]) unless args[:approval_type].nil?

  object[:settings].merge!(enforce_login: args[:enforce_login]) unless args[:enforce_login].nil?

  {
    event: "webinar.updated",
    payload: {
      account_id: "uS-ca7K2S4iRHBFqVydIfw",
      operator: "mark.vanlandingham@discourse.org",
      operator_id: "IoDo0vbMSeyrPME4fgbwxA",
      object: object,
      old_object: old_object,
    },
    time_stamp: args[:timestamp] || 1_578_575_214_322,
  }
end

def webinar_started(args = {})
  object = { id: args[:zoom_id] }

  { event: "webinar.started", payload: { account_id: "uS-ca7K2S4iRHBFqVydIfw", object: object } }
end

def webinar_participant_joined(args = {})
  webinar_participant_event("joined", args)
end
def webinar_participant_left(args = {})
  webinar_participant_event("left", args)
end

def webinar_participant_event(type, args = {})
  {
    event: "webinar.participant_#{type}",
    payload: {
      account_id: "o8KK_AAACq6BBEyA70CA",
      operator: "someemail@email.com",
      object: {
        uuid: "czLF6FFFoQOKgAB99DlDb9g==",
        id: args[:webinar_id] || "111111111",
        host_id: "uLoRgfbbTayCX6r2Q_qQsQ",
        topic: "My Meeting",
        type: 2,
        start_time: "2019-07-09T17:00:00Z",
        duration: 60,
        timezone: "America/Los_Angeles",
        participant: {
          user_id: "16782040",
          user_name: "shree",
          id: "iFxeBPYun6SAiWUzBcEkX",
          leave_time: "2019-07-16T17:13:13Z",
        },
      },
    },
  }
end

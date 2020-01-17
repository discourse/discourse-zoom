# frozen_string_literal: true

require "rails_helper"
require_relative '../fabricators/webinar_fabricator.rb'

def webinar_updated(args = {})
  old_object = { "id": args[:zoom_id] }
  object = { "id": args[:zoom_id], settings: {}}

  unless args[:start_time].nil?
    object.merge!({ "start_time": args[:start_time] })
  end

  unless args[:duration].nil?
    object.merge!({ "duration": args[:duration] })
  end

  unless args[:approval_type].nil?
    object[:settings].merge!({ "approval_type": args[:approval_type] })
  end

  unless args[:enforce_login].nil?
    object[:settings].merge!({ "enforce_login": args[:enforce_login] })
  end

  {
    "event": "webinar.updated",
    "payload": {
      "account_id": "uS-ca7K2S4iRHBFqVydIfw",
      "operator": "mark.vanlandingham@discourse.org",
      "operator_id": "IoDo0vbMSeyrPME4fgbwxA",
      "object": object,
      "old_object": old_object
      },
      "time_stamp": args[:timestamp] || 1578575214322
    }
end

describe Zoom::WebhooksController do
  let!(:zoom_id) { '1234' }

  describe "mismatched zoom authorization token" do
    before do
      SiteSetting.zoom_verification_token = ""
    end
    it "errors for webinar_registration_created" do
      post "/zoom/webhooks/webinars.json", params: { webhook: webinar_updated }, headers: { "Authorization": "123" }
      expect(response.status).to eq(403)
      expect(response.body).to include("invalid_access")
    end
  end

  describe "authorized webhooks" do
    fab!(:topic) { Fabricate(:topic) }
    let!(:verification_token) { "15123" }

    before do
      SiteSetting.zoom_verification_token = verification_token
    end

    describe "#webinar_updated" do
      fab!(:webinar) { Fabricate(:webinar, topic: topic, zoom_id: 123, duration: 60) }

      it "updates starts_at and ends_at when start_time changes" do
        start_time = "2020-02-29T18:00:00Z"
        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_updated(zoom_id: 123, start_time: start_time) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.starts_at).to eq(start_time)
        expect(webinar.ends_at).to eq(DateTime.parse(start_time) + 60.minutes)
      end

      it "updates ends_at when duration changes" do
        duration = 120
        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_updated(zoom_id: 123, duration: duration) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.duration).to eq(duration)
        expect(webinar.ends_at).to eq(webinar.starts_at + duration.minutes)
      end

      it "updates starts_at and ends_at when start_time and duration change" do
        start_time = "2020-03-13T18:00:00Z"
        duration = 180
        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_updated(zoom_id: 123, start_time: start_time, duration: duration) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.starts_at).to eq(start_time)
        expect(webinar.duration).to eq(duration)
        expect(webinar.ends_at).to eq(webinar.starts_at + duration.minutes)
      end

      it "updates settings" do
        approval_type = 0
        enforce_login = true
        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_updated(zoom_id: 123, approval_type: approval_type, enforce_login: enforce_login) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        webinar.reload
        expect(webinar.approval_type).to eq(Webinar.approval_types.key(approval_type))
        expect(webinar.enforce_login).to eq(enforce_login)
      end

    end
  end

end

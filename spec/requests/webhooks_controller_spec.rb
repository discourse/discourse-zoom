# frozen_string_literal: true

require "rails_helper"

Fabricator(:webinar) do
  title "Test webinar"
  starts_at 6.hours.from_now
  ends_at 7.hours.from_now
  duration 60
  zoom_host_id 'a1a1k1k30291'
end

def webinar_registration_created(args = {})
  {
   "event": "webinar.registration_created",
   "payload": {
     "account_id": "uS-ca7K2S4iRHBFqVydIfw",
     "object": {
       "uuid": "j6RfoGQHQIiiPKfaozGBOg==",
       "id": args[:zoom_id],
       "host_id": "IoDo0vbMSeyrPME4fgbwxA",
       "topic": "My Test Webinarz",
       "type": 5,
       "start_time": "2020-01-10T15:00:00Z",
       "duration": 60,
       "timezone": "America/Los_Angeles",
       "registrant": {
         "id": "lR-IYqD9QUe09DlR6IjA9g",
         "first_name": "Mark",
         "last_name": "VanLandingham",
         "email": args[:email],
         "address": "",
         "city": "",
         "country": "",
         "zip": "",
         "state": "",
         "phone": "",
         "industry": "",
         "org": "",
         "job_title": "",
         "purchasing_time_frame": "",
         "role_in_purchase_process": "",
         "no_of_employees": "",
         "comments": "",
         "custom_questions": [],
         "status": "approved",
         "join_url": "https://zoom.us/w/zoom_id?tk=dwub0-N4Zg85lW7QIK4EzsLFQS-lpr1AC2hSVZxCpvY.DQEAAAAAGjwH6hZsUi1JWXFEOVFVZTA5RGxSNklqQTlnAA&pwd=RmNZUzh5OEJWcFZBMXJvcTRod0pkdz09"
       }
     }
   }
 }
end

def webinar_registration_approved(args = {})
  {
    "event": "webinar.registration_approved",
    "payload": {
      "account_id": "uS-ca7K2S4iRHBFqVydIfw",
      "operator": "mark.vanlandingham@discourse.org",
      "operator_id": "IoDo0vbMSeyrPME4fgbwxA",
      "object": {
        "uuid": "j6RfoGQHQIiiPKfaozGBOg==",
        "id": args[:zoom_id],
        "host_id": "IoDo0vbMSeyrPME4fgbwxA",
        "topic": "My Test Webinarz",
        "type": 5,
        "start_time": "2020-01-10T15:00:00Z",
        "duration": 60,
        "timezone": "America/Los_Angeles",
        "registrant": {
          "id": "k0DJmwsNQzeSazgE8nn6wQ",
          "first_name": "Mark",
          "last_name": "VanLandingham",
          "email": args[:email]
        }
      }
    }
  }
end

def webinar_registration_cancelled(args = {})
  {
    "event": "webinar.registration_cancelled",
    "payload": {
      "account_id": "uS-ca7K2S4iRHBFqVydIfw",
      "operator": "mark.vanlandingham@discourse.org",
      "operator_id": "IoDo0vbMSeyrPME4fgbwxA",
      "object": {
        "uuid": "j6RfoGQHQIiiPKfaozGBOg==",
        "id": args[:zoom_id],
        "host_id": "IoDo0vbMSeyrPME4fgbwxA",
        "topic": "My Test Webinarz",
        "type": 5,
        "start_time": "2020-01-10T15:00:00Z",
        "duration": 60,
        "timezone": "America/Los_Angeles",
        "registrant": {
          "id": "k0DJmwsNQzeSazgE8nn6wQ",
          "first_name": "Mark",
          "last_name": "VanLandingham",
          "email": args[:email]
        }
      }
    }
  }
end

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
      post "/zoom/webhooks/webinars.json", params: { webhook: webinar_registration_created }, headers: { "Authorization": "123" }
      expect(response.status).to eq(403)
      expect(response.body).to include("invalid_access")
    end
    it "errors for webinar_registration_approved" do
      post "/zoom/webhooks/webinars.json", params: { webhook: webinar_registration_cancelled }, headers: { "Authorization": "123" }
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

    describe "#webinar_registration_created" do
      fab!(:existing_user) { Fabricate(:user) }
      it "created a staged user and registers them for a webinar" do
        email = "markvanlan@gmail.com"
        expect(User.find_by_email(email)).to eq(nil)

        webinar = Webinar.create(topic: topic, zoom_id: zoom_id)

        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_registration_created(zoom_id: zoom_id, email: email) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        expect(webinar.users.first.email).to eq(email)
        expect(User.find_by_email(email).staged).to be_truthy
      end

      it "registers existing users for the webinar" do
        existing_user
        webinar = Webinar.create(topic: topic, zoom_id: zoom_id)

        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_registration_created(zoom_id: zoom_id, email: existing_user.email) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)
        expect(webinar.users.first).to eq(existing_user)
      end
    end

    describe "#webinar_registration_cancelled" do
      fab!(:user) { Fabricate(:user) }

      it "removes users" do
        webinar = Webinar.create(topic: topic, zoom_id: zoom_id)
        webinar.webinar_users.create(user: user, type: 'attendee')
        expect(webinar.users.count).to eq(1)
        post "/zoom/webhooks/webinars.json",
          params: { webhook: webinar_registration_cancelled(zoom_id: zoom_id, email: user.email) },
          headers: { "Authorization": verification_token }
        expect(response.status).to eq(200)

        webinar_user = webinar.webinar_users.reload.first
        expect(webinar_user.user).to eq(user)
        expect(webinar_user.registration_status).to eq("rejected")
      end
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

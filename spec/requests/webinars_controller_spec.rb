# frozen_string_literal: true

require "rails_helper"
require_relative "../responses/zoom_api_stubs"

describe Zoom::WebinarsController do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:user, username: "mark.vanlan", admin: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  let(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

  before do
    SiteSetting.zoom_enabled = true
    SiteSetting.s2s_oauth_token = "Test_Token"
  end

  describe "#show" do
    it "works for anons" do
      get "/zoom/webinars/#{webinar.id}.json"
      json = JSON.parse(response.body)

      expect(response.status).to eq(200)
      expect(json["webinar"]["topic_id"]).to eq(topic.id)
    end
  end

  describe "#destroy" do
    it "requires the user to be logged in" do
      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(403)
    end

    it "requires the user to be able to edit the topic" do
      sign_in(other_user)
      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(403)
    end

    it "Removes the webinar and webinar_users" do
      sign_in(user)
      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(200)
      expect(WebinarUser.where(webinar_id: webinar.id).count).to eq(0)
      expect(topic.reload.webinar).to eq(nil)
    end
  end

  describe "#add_panelist" do
    before do
      stub_request(:post, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists").to_return(
        status: 201,
      )
    end

    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "requires the user to be able to edit the topic" do
      sign_in(other_user)
      put("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "Adds a panelist to the webinar" do
      sign_in(user)
      expect(webinar.panelists.include? user).to eq(false)
      put("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")

      expect(response.status).to eq(200)
      expect(webinar.panelists.include? user).to eq(true)
    end

    it "Adds a panelist to the webinar when the username has a '.'" do
      sign_in(admin)
      expect(webinar.panelists.include? admin).to eq(false)
      put("/zoom/webinars/#{webinar.id}/panelists/#{admin.username}.json")
      expect(response.status).to eq(200)
      expect(webinar.panelists.include? admin).to eq(true)
    end
  end

  describe "#add_nonzoom_panelist" do
    it "Adds panelist to a nonzoom webinar" do
      webinar.zoom_id = "nonzoom"
      webinar.save

      sign_in(admin)
      expect(webinar.panelists.include? admin).to eq(false)
      put("/zoom/webinars/#{webinar.id}/panelists/#{admin.username}.json")
      expect(response.status).to eq(200)
      expect(webinar.panelists.include? admin).to eq(true)
    end
  end

  describe "#remove_panelist" do
    before do
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists").to_return(
        status: 201,
        body: { panelists: [{ id: "123", email: user.email }] }.to_json,
      )
      stub_request(
        :delete,
        "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists/123",
      ).to_return(status: 204)
    end

    it "requires the user to be logged in" do
      delete("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "requires the user to be able to edit the topic" do
      sign_in(other_user)
      delete("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "Removes the users as a panelist" do
      sign_in(user)
      webinar.webinar_users.create(user: user, type: :panelist)
      expect(webinar.panelists.include? user).to eq(true)
      delete("/zoom/webinars/#{webinar.id}/panelists/#{user.username}.json")
      expect(response.status).to eq(200)
      expect(webinar.panelists.include? user).to eq(false)
    end
  end

  describe "#update_nonzoom_host" do
    it "Updates host of a nonzoom webinar" do
      webinar.zoom_id = "nonzoom"
      webinar.save

      sign_in(admin)
      expect(webinar.host).to eq(nil)
      put("/zoom/webinars/#{webinar.id}/nonzoom_host/#{admin.username}.json")
      expect(response.status).to eq(200)
      expect(webinar.host).to eq(admin)
    end

    it "does not update host of a regular webinar" do
      sign_in(admin)
      expect(webinar.host).to eq(nil)
      put("/zoom/webinars/#{webinar.id}/nonzoom_host/#{admin.username}.json")
      expect(response.status).to eq(404)
      expect(webinar.host).to eq(nil)
    end

    it "requires the user to be able to edit the topic" do
      sign_in(other_user)
      put("/zoom/webinars/#{webinar.id}/nonzoom_host/#{admin.username}.json")
      expect(response.status).to eq(403)
    end
  end

  describe "#update_nonzoom_details" do
    it "requires both title and past_start_date parameters" do
      webinar.zoom_id = "nonzoom"
      webinar.save

      sign_in(admin)

      put("/zoom/webinars/#{webinar.id}/nonzoom_details.json")
      expect(response.status).to eq(400)

      put("/zoom/webinars/#{webinar.id}/nonzoom_details.json", params: { title: "Some title" })
      expect(response.status).to eq(400)

      put(
        "/zoom/webinars/#{webinar.id}/nonzoom_details.json",
        params: {
          past_start_date: Time.now,
        },
      )
      expect(response.status).to eq(400)
    end

    it "updates title and date" do
      webinar.zoom_id = "nonzoom"
      webinar.starts_at = 5.days.ago
      webinar.save

      sign_in(admin)
      put(
        "/zoom/webinars/#{webinar.id}/nonzoom_details.json",
        params: {
          past_start_date: 2.days.ago,
          title: "New balls, please",
        },
      )

      expect(response.status).to eq(200)
      webinar.reload
      expect(webinar.starts_at).to be_within(1.minute).of 2.days.ago
      expect(webinar.title).to eq("New balls, please")
    end

    it "requires the user to be able to edit the topic" do
      sign_in(other_user)
      put(
        "/zoom/webinars/#{webinar.id}/nonzoom_details.json",
        params: {
          past_start_date: 2.days.ago,
          title: "Paper planes",
        },
      )
      expect(response.status).to eq(403)
    end
  end

  describe "#register" do
    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/attendees/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "registers the user for the webinar" do
      sign_in(user)
      expect(webinar.attendees.include? user).to eq(false)

      put("/zoom/webinars/#{webinar.id}/attendees/#{user.username}.json")

      expect(response.status).to eq(200)
      expect(webinar.attendees.include? user).to eq(true)
    end

    it "registers the user for the webinar with '.' in the username" do
      sign_in(admin)
      expect(webinar.attendees.include? admin).to eq(false)

      put("/zoom/webinars/#{webinar.id}/attendees/#{admin.username}.json")

      expect(webinar.attendees.include? admin).to eq(true)
    end
  end

  describe "#unregister" do
    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/attendees/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "registers the user for the webinar" do
      sign_in(user)
      webinar.webinar_users.create(user: user, type: :attendee)
      expect(webinar.attendees.include? user).to eq(true)

      delete("/zoom/webinars/#{webinar.id}/attendees/#{user.username}.json")

      expect(response.status).to eq(200)
      expect(webinar.attendees.include? user).to eq(false)
    end
  end

  describe "#destroy" do
    it "requires the user to be logged in" do
      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(403)
    end

    it "requires the user to be able to manage the topic" do
      sign_in(other_user)

      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(403)
    end

    it "deletes the webinar and webinar users" do
      sign_in(user)

      delete("/zoom/webinars/#{webinar.id}.json")
      expect(response.status).to eq(200)
      expect(topic.reload.webinar).to eq(nil)
    end
  end

  describe "#add_to_topic" do
    let(:other_topic) { Fabricate(:topic, user: user) }
    let(:yet_another_topic) { Fabricate(:topic, user: user) }
    let(:zoom_id) { "123" }
    before { Webinar.where(zoom_id: zoom_id).destroy_all }

    describe "zoom events" do
      before do
        stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}").to_return(
          status: 201,
          body: ZoomApiStubs.get_webinar(zoom_id),
        )
        stub_request(:get, "https://api.zoom.us/v2/users/123").to_return(
          status: 201,
          body: ZoomApiStubs.get_host("123"),
        )
        stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}/panelists").to_return(
          status: 201,
          body: { panelists: [{ id: "123", email: user.email }] }.to_json,
        )
      end
      it "requires the user to be logged in" do
        put("/zoom/t/#{other_topic.id}/webinars/#{zoom_id}.json")
        expect(response.status).to eq(403)
      end

      it "adds the webinar to the existing topic" do
        sign_in(user)
        expect(other_topic.webinar).to eq(nil)
        put("/zoom/t/#{other_topic.id}/webinars/#{zoom_id}.json")
        expect(response.status).to eq(200)
        expect(other_topic.reload.webinar).to eq(Webinar.last)
      end
    end

    it "adds a nonzoom webinar to a topic" do
      sign_in(user)
      expect(yet_another_topic.webinar).to eq(nil)
      webinar_date = 3.days.ago
      put(
        "/zoom/t/#{yet_another_topic.id}/webinars/nonzoom.json",
        params: {
          zoom_start_date: webinar_date,
          zoom_title: "Fake webinar",
        },
      )

      expect(response.status).to eq(200)

      webinar = yet_another_topic.reload.webinar
      expect(webinar).to eq(Webinar.last)
      expect(webinar.starts_at).to be_within(1.minute).of webinar_date
    end
  end

  describe "#set_video_url" do
    let(:video_url) { "hello.mp4" }
    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/video_url.json", params: { video_url: video_url })
      expect(response.status).to eq(403)
    end

    it "requires the user to be able to manage the topic" do
      sign_in(other_user)

      put("/zoom/webinars/#{webinar.id}/video_url.json", params: { video_url: video_url })
      expect(response.status).to eq(403)
    end

    it "puts the webinar and webinar users" do
      sign_in(user)

      put("/zoom/webinars/#{webinar.id}/video_url.json", params: { video_url: video_url })
      expect(response.status).to eq(200)
      expect(webinar.reload.video_url).to eq(video_url)
    end
  end

  describe "#watch" do
    it "fires a DiscourseEvent" do
      sign_in(user)

      events =
        DiscourseEvent.track_events do
          put "/zoom/webinars/#{webinar.id}/attendees/#{user.username}/watch.json"
        end

      expect(events.map { |event| event[:event_name] }).to include(:webinar_participant_watched)
    end
  end

  describe "#sdk" do
    it "gets the embeded view for a webinar" do
      sign_in(user)

      get "/zoom/webinars/#{webinar.id}/sdk?fallback=1"
      expect(response.status).to eq(200)
      expect(response.headers["Content-Security-Policy"]).to include("'unsafe-eval'")
    end
  end

  describe "#preview" do
    context "when Webinar plan missing" do
      before do
        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}").with(
          headers: {
            "Authorization" => "Bearer Test_Token",
            "Content-Type" => "application/json",
            "Host" => "api.zoom.us",
          },
        ).to_return(
          { status: 401, body: { "code" => 200, "message" => "Webinar plan is missing." }.to_json },
          { status: 401, body: { "code" => 200, "message" => "Webinar plan is missing." }.to_json },
        )

        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}/panelists").to_return(
          status: 201,
          body: { panelists: [{ id: "123", email: user.email }] }.to_json,
        )

        stub_request(
          :post,
          "https://zoom.us/oauth/token?account_id=&grant_type=account_credentials",
        ).with(
          headers: {
            "Authorization" => "Basic  Og==",
            "Content-Type" => "application/json",
            "Host" => "zoom.us",
          },
        ).to_return(
          {
            body: { access_token: "token" }.to_json,
            headers: {
              content_type: "application/json",
            },
            status: 200,
          },
          {
            body: { access_token: "token" }.to_json,
            headers: {
              content_type: "application/json",
            },
            status: 200,
          },
        )

        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}").with(
          headers: {
            "Authorization" => "Bearer token",
            "Content-Type" => "application/json",
            "Host" => "api.zoom.us",
          },
        ).to_return(
          { status: 401, body: { "code" => 200, "message" => "Webinar plan is missing." }.to_json },
        )

        sign_in(user)
      end
      it "creates problem check error" do
        get "/zoom/webinars/#{webinar.id}/preview.json"

        expect(response.status).to eq(403)
        expect(AdminNotice.problem.last.message).to eq(
          I18n.t("dashboard.problem.s2s_webinar_subscription", message: "Webinar plan is missing."),
        )
      end
    end

    context "when Webinar missing" do
      let(:fake_logger) { FakeLogger.new }

      before do
        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}").with(
          headers: {
            "Authorization" => "Bearer Test_Token",
            "Content-Type" => "application/json",
            "Host" => "api.zoom.us",
          },
        ).to_return(
          {
            status: 404,
            body: { code: 3001, message: "Meeting is not found or has expired." }.to_json,
          },
          {
            status: 404,
            body: { code: 3001, message: "Meeting is not found or has expired." }.to_json,
          },
        )

        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}/panelists").to_return(
          status: 201,
          body: { panelists: [{ id: "123", email: user.email }] }.to_json,
        )

        stub_request(
          :post,
          "https://zoom.us/oauth/token?account_id=&grant_type=account_credentials",
        ).with(
          headers: {
            "Authorization" => "Basic  Og==",
            "Content-Type" => "application/json",
            "Host" => "zoom.us",
          },
        ).to_return(
          {
            body: { access_token: "token" }.to_json,
            headers: {
              content_type: "application/json",
            },
            status: 200,
          },
          {
            body: { access_token: "token" }.to_json,
            headers: {
              content_type: "application/json",
            },
            status: 200,
          },
        )

        stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.id}").with(
          headers: {
            "Authorization" => "Bearer token",
            "Content-Type" => "application/json",
            "Host" => "api.zoom.us",
          },
        ).to_return(
          {
            status: 404,
            body: { code: 3001, message: "Meeting is not found or has expired." }.to_json,
          },
        )

        Rails.logger.broadcast_to(fake_logger)

        sign_in(user)
      end

      after { Rails.logger.stop_broadcasting_to(fake_logger) }

      it "shows the correct error message for code 3001" do
        get "/zoom/webinars/#{webinar.id}/preview.json"
        json = JSON.parse(response.body)

        expect(response.status).to eq(404)
      end
    end
  end
end

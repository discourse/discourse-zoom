# frozen_string_literal: true

require "rails_helper"
require_relative "../responses/zoom_api_stubs"

describe Zoom::WebinarsController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:user, username: "mark.vanlan", admin: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  let(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

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
      stub_request(:post, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists").to_return(status: 201)
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

  describe "#remove_panelist" do
    before do
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists").to_return(status: 201, body: {
        panelists: [{ id: "123", email: user.email }] }.to_json
      )
      stub_request(:delete, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/panelists/123").to_return(status: 204)
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
    let(:zoom_id) { "123" }
    before do
      Webinar.where(zoom_id: zoom_id).destroy_all
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}").to_return(status: 201, body: ZoomApiStubs.get_webinar(zoom_id))
      stub_request(:get, "https://api.zoom.us/v2/users/123").to_return(status: 201, body: ZoomApiStubs.get_host('123'))
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}/panelists").to_return(status: 201, body: {
        panelists: [{ id: "123", email: user.email }] }.to_json
      )
    end
    it "requires the user to be logged in" do
      put("/zoom/t/#{other_topic.id}/webinars/#{zoom_id}.json")
      expect(response.status).to eq(403)
    end

    it "registers the user for the webinar" do
      sign_in(user)
      expect(other_topic.webinar).to eq(nil)
      put("/zoom/t/#{other_topic.id}/webinars/#{zoom_id}.json")
      expect(response.status).to eq(200)
      expect(other_topic.reload.webinar).to eq(Webinar.last)
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

      DiscourseEvent.expects(:trigger).with() { |eventName, eventWebinar, eventUser |
        eventName === :webinar_participant_watched &&
        eventWebinar === webinar &&
        eventUser === user
      }.once
      put("/zoom/webinars/#{webinar.id}/attendees/#{user.username}/watch.json")
    end
  end
end

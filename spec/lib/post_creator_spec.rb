# frozen_string_literal: true

require "rails_helper"
require_relative "../responses/zoom_api_stubs"

describe PostCreator do
  let!(:title) { "Testing Zoom Webinar integration" }
  let(:zoom_id) { "123" }
  let(:user) { Fabricate(:user) }

  before do
    SiteSetting.min_first_post_typing_time = 0
    SiteSetting.zoom_enabled = true
  end

  describe "creating a topic with webinar" do
    it "works" do
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}").to_return(status: 201, body: ZoomApiStubs.get_webinar(zoom_id))
      stub_request(:get, "https://api.zoom.us/v2/users/#{zoom_id}").to_return(status: 201, body: ZoomApiStubs.get_host(zoom_id))
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{zoom_id}/panelists").to_return(status: 201, body: {
        panelists: [{ id: "123", email: user.email }] }.to_json
      )

      post = PostCreator.new(
        user,
        title: title,
        raw: "Here comes the rain again",
        zoom_id: zoom_id
      ).create

      expect(post.topic.webinar.zoom_id).to eq(zoom_id)
    end

    it "creates a past webinar without calling Zoom API" do
      post = PostCreator.new(
        user,
        title: title,
        raw: "Falling on my head like a new emotion",
        zoom_id: "nonzoom",
        zoom_webinar_start_date: "Mon Mar 02 2020 00:00:00 GMT-0500 (Eastern Standard Time)",
        zoom_webinar_title: "This is a non-Zoom webinar"
      ).create

      expect(post.topic.webinar.zoom_id).to eq("nonzoom")
      expect(post.topic.webinar.host.username).to eq(user.username)
      expect(post.topic.webinar.title).to eq("This is a non-Zoom webinar")

    end

    it "ignores webinar params in replies" do
      topic = Fabricate(:topic)
      Fabricate(:post, topic: topic)

      post = PostCreator.new(
        user,
        title: title,
        raw: "You know what they say...",
        zoom_id: "nonzoom",
        zoom_webinar_start_date: "Mon Mar 02 2020 00:00:00 GMT-0500 (Eastern Standard Time)",
        zoom_webinar_title: "This is a non-Zoom webinar",
        topic_id: topic.id,
      ).create

      expect(post.topic.webinar).to eq(nil)
    end
  end
end
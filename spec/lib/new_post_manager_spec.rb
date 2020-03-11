# frozen_string_literal: true

require "rails_helper"
require_relative "../responses/zoom_api_stubs"

describe NewPostManager do
  let(:user) { Fabricate(:newuser) }

  describe "when new post contains a webinar reference" do
    let(:params) do
      {
        raw: "Here goes a Zoom test",
        archetype: "regular",
        category: "",
        typing_duration_msecs: "2700",
        composer_open_duration_msecs: "12556",
        visible: true,
        image_sizes: nil,
        is_warning: false,
        title: "This is a test post with a poll",
        ip_address: "127.0.0.1",
        user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
        referrer: "http://localhost:3000/",
        first_post_checks: true,
        zoom_id: "123"
      }
    end

    it "should create Zoom webinar from ID" do
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{params[:zoom_id]}").to_return(status: 201, body: ZoomApiStubs.get_webinar(params[:zoom_id]))
      stub_request(:get, "https://api.zoom.us/v2/users/#{params[:zoom_id]}").to_return(status: 201, body: ZoomApiStubs.get_host(params[:zoom_id]))
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{params[:zoom_id]}/panelists").to_return(status: 201, body: {
        panelists: [{ id: "123", email: user.email }] }.to_json
      )

      result = NewPostManager.new(user, params).perform
      topic = Topic.find(result.post.topic_id)

      expect(result.action).to eq(:create_post)
      expect(topic.webinar.zoom_id).to eq(params[:zoom_id])
    end

    it "should create a past webinar without calling Zoom API" do
      params[:zoom_webinar_start_date] = "Mon Mar 02 2020 00:00:00 GMT-0500 (Eastern Standard Time)"
      params[:zoom_webinar_title] = "This is a webinar in the past"
      params[:zoom_id] = "nonzoom"

      result = NewPostManager.new(user, params).perform
      topic = Topic.find(result.post.topic_id)

      expect(result.action).to eq(:create_post)
      expect(topic.webinar.zoom_id).to eq(params[:zoom_id])
      expect(topic.webinar.title).to eq(params[:zoom_webinar_title])

    end
  end
end

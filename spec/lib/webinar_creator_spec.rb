# frozen_string_literal: true

RSpec.describe Zoom::WebinarCreator do
  describe "#run" do
    it "creates a webinar" do
      stub_request(:post, "https://zoom.us/oauth/token?account_id=&grant_type=account_credentials")
        .to_return(status: 200, body: {}.to_json, headers: {})
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{123}")
        .to_return(status: 201, body: ZoomApiStubs.get_webinar(123, 456))
      stub_request(:get, "https://api.zoom.us/v2/users/456").to_return(
        status: 200, body: ZoomApiStubs.get_host("456"))
      stub_request(:get, "https://api.zoom.us/v2/webinars/123/panelists")
        .to_return(status: 201, body: { panelists: [] }.to_json)

      creator = described_class.new(topic_id: 12112, zoom_id: "123")

      expect { creator.run }.to change { Webinar.count }.by(1)
      expect(Webinar.last).to have_attributes(
        zoom_id: "123",
        zoom_host_id: "456"
      )
    end
  end
end

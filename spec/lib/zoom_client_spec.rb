# frozen_string_literal: true

RSpec.describe Zoom::Client do
  describe "#webinar" do
    it "returns a webinar object" do
      stub_request(:post, "https://zoom.us/oauth/token?account_id=&grant_type=account_credentials")
        .to_return(status: 200, body: {}.to_json, headers: {})
      stub_request(:get, "https://api.zoom.us/v2/webinars/#{123}")
        .to_return(status: 201, body: ZoomApiStubs.get_webinar(123))

      client = described_class.new
      webinar_response = JSON.parse(ZoomApiStubs.get_webinar(123))
      webinar = client.webinar("123")

      expect(webinar).to eq(
        id: "#{webinar_response["id"]}",
        title: webinar_response["topic"],
        starts_at: DateTime.parse(webinar_response["start_time"]),
        duration: webinar_response["duration"],
        ends_at: DateTime.parse(webinar_response["start_time"]) + webinar_response["duration"].to_i.minutes,
        host_id: webinar_response["host_id"],
        password: webinar_response["password"],
        host_video: webinar_response["settings"]["host_video"],
        panelists_video: webinar_response["settings"]["panelists_video"],
        approval_type: webinar_response["settings"]["approval_type"],
        enforce_login: webinar_response["settings"]["enforce_login"],
        registrants_restrict_number: webinar_response["settings"]["registrants_restrict_number"],
        meeting_authentication: webinar_response["settings"]["meeting_authentication"],
        on_demand: webinar_response["settings"]["on_demand"],
        join_url: webinar_response["settings"]["join_url"],
      )
    end
  end
end

# frozen_string_literal: true

RSpec.describe Zoom::Client do
  describe "#webinar" do
    it "returns a webinar object" do
      expected_body = {
        topic: "Test Webinar",
        start_time: "2021-09-20T12:00:00Z",
        duration: 60,
        host_id: "456",
        password: "password",
        settings: {
          host_video: true,
          panelists_video: true,
          approval_type: 0,
          enforce_login: false,
          registrants_restrict_number: 0,
          meeting_authentication: false,
          on_demand: false,
          join_url: "https://zoom.us/j/123",
        },
      }
      Zoom::OAuthClient
        .stubs(:new)
        .with(Zoom::Client::API_URL, "webinars/123")
        .returns(mock("Zoom::OAuthClient", get: mock(body: expected_body)))

      client = described_class.new
      webinar = client.webinar("123")

      expect(webinar).to eq(
        id: "123",
        title: "Test Webinar",
        starts_at: DateTime.parse("2021-09-20T12:00:00Z"),
        duration: 60,
        ends_at: DateTime.parse("2021-09-20T13:00:00Z"),
        host_id: "456",
        password: "password",
        host_video: true,
        panelists_video: true,
        approval_type: 0,
        enforce_login: false,
        registrants_restrict_number: 0,
        meeting_authentication: false,
        on_demand: false,
        join_url: "https://zoom.us/j/123",
      )
    end
  end
end

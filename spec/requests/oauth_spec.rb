# frozen_string_literal: true

require "rails_helper"
require_relative "../responses/zoom_api_stubs"

describe Zoom::OAuthClient do
  fab!(:user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:user, username: "admin.user", admin: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  let!(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }
  let!(:valid_token) { "valid_token" }
  let!(:invalid_token) { "invalid_token" }
  let!(:end_point) { "webinars/#{webinar.zoom_id}" }
  let!(:body) do
    body = { grant_type: "account_credentials", account_id: SiteSetting.zoom_s2s_account_id }
    body = URI.encode_www_form(body)
    body
  end
  describe "#get_oauth" do
    describe "oauth_token" do
      before do
        SiteSetting.zoom_s2s_account_id = "123456"
        stub_request(:get, "#{Zoom::Client::API_URL}#{end_point}").with(
          headers: {
            Authorization: "Bearer #{valid_token}",
            Host: "api.zoom.us",
          },
        ).to_return(body: ZoomApiStubs.get_webinar(user.id), status: 200)
        stub_request(:get, "#{Zoom::Client::API_URL}#{end_point}").with(
          headers: {
            Authorization: "Bearer #{invalid_token}",
            Host: "api.zoom.us",
          },
        ).to_return(body: "", status: 400)
        stub_request(:get, "#{Zoom::Client::API_URL}#{end_point}").with(
          headers: {
            Authorization: "Bearer not_a_valid_token",
            Host: "api.zoom.us",
          },
        ).to_return(status: 400)
      end
      describe "valid/present" do
        before { SiteSetting.s2s_oauth_token = valid_token }
        it "makes api calls" do
          response = described_class.new(Zoom::Client::API_URL, end_point).get
          expect(response.status).to eq(200)
        end
      end
      describe "invalid/not present" do
        describe "uses valid account authorization" do
          before do
            stub_request(
              :post,
              "https://zoom.us/oauth/token?account_id=123456&grant_type=account_credentials",
            ).with(
              headers: {
                Authorization: "Basic  Og==",
                Content_Type: "application/json",
                Host: "zoom.us",
              },
            ).to_return(
              body: { access_token: valid_token }.to_json,
              headers: {
                content_type: "application/json",
              },
              status: 200,
            )
          end
          it "requests a new oauth_token" do
            SiteSetting.s2s_oauth_token = invalid_token
            response = described_class.new(Zoom::Client::API_URL, end_point).get
            expect(response.status).to eq(200)
          end
        end

        describe "uses invalid authorization" do
          before do
            stub_request(
              :post,
              "https://zoom.us/oauth/token?account_id=123456&grant_type=account_credentials",
            ).with(
              headers: {
                Authorization: "Basic  Og==",
                Content_Type: "application/json",
                Host: "zoom.us",
              },
            ).to_return(
              body: { access_token: "not_a_valid_token" }.to_json,
              headers: {
                content_type: "application/json",
              },
              status: 200,
            )
          end
          it "can't request a new oauth_token" do
            SiteSetting.s2s_oauth_token = "not_a_valid_token"
            expect { described_class.new(Zoom::Client::API_URL, end_point).get }.to raise_error(
              Discourse::InvalidAccess,
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Zoom::WebinarsController do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:user) { Fabricate(:user) }
  let(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

  before do
    stub_request(:post, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/registrants").to_return(status: 201)
  end

  describe "#register" do
    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/register/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "registers the user for the webinar" do
      sign_in(user)
      put("/zoom/webinars/#{webinar.id}/register/#{user.username}.json")
      expect(response.status).to eq(200)
    end
  end

end

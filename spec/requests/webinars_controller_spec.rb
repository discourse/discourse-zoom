# frozen_string_literal: true

require "rails_helper"

describe Zoom::WebinarsController do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:user) { Fabricate(:user) }
  let(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

  describe "#register" do
    before do
      stub_request(:post, "https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/registrants").to_return(status: 201)
    end

    it "requires the user to be logged in" do
      put("/zoom/webinars/#{webinar.id}/register/#{user.username}.json")
      expect(response.status).to eq(403)
    end

    it "registers the user for the webinar" do
      sign_in(user)
      expect(WebinarUser.where(user: user, webinar: webinar).count).to eq(0)

      put("/zoom/webinars/#{webinar.zoom_id}/register/#{user.username}.json")

      expect(response.status).to eq(200)
      expect(WebinarUser.where(user: user, webinar: webinar).count).to eq(1)
    end
  end

end

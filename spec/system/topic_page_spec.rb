# frozen_string_literal: true

describe "Discourse Zoom | Topic Page", type: :system do
  fab!(:topic)
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

  before { SiteSetting.zoom_enabled = true }

  it "renders successfully" do
    visit "/t/#{topic.slug}/#{topic.id}"
    expect(page).to have_css(".webinar-banner")
    expect(page).to have_css("body.has-webinar")
  end
end

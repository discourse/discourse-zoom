# frozen_string_literal: true

describe "Discourse Zoom | Topic Page", type: :system do
  %w[enabled disabled].each do |value|
    before { SiteSetting.glimmer_post_stream_mode = value }

    context "when glimmer_post_stream_mode=#{value}" do
      fab!(:topic, :topic_with_op)
      fab!(:webinar) { Webinar.create(topic:, zoom_id: "123") }

      before { SiteSetting.zoom_enabled = true }

      it "renders successfully" do
        visit "/t/#{topic.slug}/#{topic.id}"
        expect(page).to have_css(".webinar-banner")
        expect(page).to have_css("body.has-webinar")
      end
    end
  end
end

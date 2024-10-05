# frozen_string_literal: true

require "rails_helper"
RSpec.describe ProblemCheck::S2sWebinarSubscription do
  before do
    stub_request(:get, "https://api.zoom.us/v2/webinars/123456").to_return(
      status: 401,
      body: { "error" => { "code" => 200, "message" => "Webinar plan is missing." } }.to_json,
    )
  end
  it "raise a error and trigger a problem check when the server returns a code 200" do
    ProblemCheckTracker[:s2s_webinar_subscription].no_problem!

    get "/zoom/webinars/123456/preview.json"

    expect(AdminNotice.problem.last.message).to eq(
      I18n.t("dashboard.problem.s2s_webinar_subscription", message: "Webinar plan is missing."),
    )
  end
end

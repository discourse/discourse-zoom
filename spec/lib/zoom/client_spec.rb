# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Zoom::Client do
  let(:webinar_id) { '818854723' }

  it 'reads the webinar data from the Zoom API' do
    payload = read_payload('webinar')
    stub_get("webinars/#{webinar_id}", payload)
    expected_data = JSON.parse(payload, symbolize_names: true)

    webinar_data = subject.webinar(webinar_id)

    start_time = DateTime.parse(expected_data[:start_time])
    duration = expected_data[:duration]
    expect(webinar_data[:title]).to eq expected_data[:topic]
    expect(webinar_data[:starts_at]).to eq start_time
    expect(webinar_data[:duration]).to eq duration
    expect(webinar_data[:ends_at]).to eq start_time + duration.minutes
    expect(webinar_data[:zoom_host_id]).to eq expected_data[:host_id]
  end

  it 'reads the host data from the Zoom API' do
    host_id = "f8ARIoV7RfewqgwegwDqcwh5W1i_Q2g"
    payload = read_payload('host')
    stub_get("users/#{host_id}", payload)
    expected_data = JSON.parse(payload, symbolize_names: true)

    host_data = subject.host(host_id)

    expect(host_data[:name]).to eq "#{expected_data[:first_name]} #{expected_data[:last_name]}"
    expect(host_data[:avatar_url]).to eq expected_data[:pic_url]
    expect(host_data[:email]).to eq expected_data[:email]
  end

  it 'reads the speakers data from the Zoom API' do
    payload = read_payload('speakers')
    stub_get("webinars/#{webinar_id}/panelists", payload)
    expected_data = JSON.parse(payload, symbolize_names: true)[:panelists].first

    speaker_data = subject.speakers(webinar_id)[:speakers].first

    expect(speaker_data[:email]).to eq expected_data[:email]
    expect(speaker_data[:name]).to eq expected_data[:name]
  end

  def read_payload(payload_name)
    File.read(
      File.expand_path("../../../fixtures/zoom/#{payload_name}.json", __FILE__)
    )
  end

  def stub_get(endpoint, payload)
    SiteSetting.zoom_api_key = "121212"
    SiteSetting.zoom_api_secret = "very_secret"
    token = described_class.new.jwt_token

    stub_request(:get, "#{described_class::API_URL}#{endpoint}")
      .with(headers: { 'Authorization': "Bearer #{token}" })
      .to_return(body: payload, status: 200, headers: {})
  end
end

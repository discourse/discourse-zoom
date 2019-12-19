# frozen_string_literal: true

require_relative '../../helpers/fake_zoom.rb'

RSpec.describe Zoom::Webinars do
  describe "#preview" do
    let(:webinar_id) { '818854723' }

    it 'includes the webinar data' do
      webinar_data = webinars_calendar.preview(webinar_id)

      expect(webinar_data[:title]).to be_present
      expect(webinar_data[:starts_at]).to be_present
      expect(webinar_data[:ends_at]).to be_present
      expect(webinar_data[:duration]).to be_present
    end

    it 'includes the host data' do
      webinar_data = webinars_calendar.preview(webinar_id)

      expect(webinar_data[:host]).to be_present
    end

    it 'includes the speakers data' do
      webinar_data = webinars_calendar.preview(webinar_id)

      expect(webinar_data[:speakers]).to be_present
    end
  end

  def webinars_calendar
    described_class.new(FakeZoom.new)
  end
end

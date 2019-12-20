# frozen_string_literal: true

require_relative '../../helpers/fake_zoom.rb'
require_relative '../../fabricators/webinar_fabricator.rb'

RSpec.describe Zoom::Webinars do
  describe "#preview" do
    let(:webinar_id) { '818854723' }

    it 'includes the webinar data' do
      webinar_data = webinars.preview(webinar_id)

      expect(webinar_data[:title]).to be_present
      expect(webinar_data[:starts_at]).to be_present
      expect(webinar_data[:ends_at]).to be_present
      expect(webinar_data[:duration]).to be_present
    end

    it 'includes the host data' do
      webinar_data = webinars.preview(webinar_id)

      expect(webinar_data[:host]).to be_present
    end

    it 'includes the speakers data' do
      webinar_data = webinars.preview(webinar_id)

      expect(webinar_data[:speakers]).to be_present
    end

    describe 'using database stored webinars when building a preview' do
      before do
        @webinar = Fabricate(:webinar, zoom_id: webinar_id)
      end

      it 'uses the available webinar data' do
        webinar_data = webinars.preview(webinar_id)

        expect(webinar_data[:title]).to eq @webinar.title
        expect(webinar_data[:starts_at]).to eq @webinar.starts_at
        expect(webinar_data[:ends_at]).to eq @webinar.ends_at
        expect(webinar_data[:duration]).to eq @webinar.duration
      end

      it 'uses the available host data' do
        host = Fabricate(:user)
        avatar_url = host.avatar_template_url.gsub('{size}', '120')
        WebinarUser.create!(webinar: @webinar, user: host, type: :host)

        webinar_data = webinars.preview(webinar_id).fetch(:host)

        expect(webinar_data[:name]).to eq host.name
        expect(webinar_data[:email]).to eq host.email
        expect(webinar_data[:avatar_url]).to eq avatar_url
      end

      it 'uses the available speakers data' do
        speaker = Fabricate(:user)
        WebinarUser.create!(webinar: @webinar, user: speaker, type: :speaker)

        webinar_data = webinars.preview(webinar_id).fetch(:speakers).first

        expect(webinar_data[:name]).to eq speaker.name
        expect(webinar_data[:email]).to eq speaker.email
      end
    end
  end

  def webinars
    described_class.new(FakeZoom.new)
  end
end

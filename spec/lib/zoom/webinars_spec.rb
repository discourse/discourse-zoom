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
        expect(webinar_data[:avatar_url]).to eq avatar_url
      end

      it 'uses the available speakers data' do
        speaker = Fabricate(:user)
        WebinarUser.create!(webinar: @webinar, user: speaker, type: :speaker)

        webinar_data = webinars.preview(webinar_id).fetch(:speakers).first

        expect(webinar_data[:name]).to eq speaker.name
      end
    end

    describe 'Searching for Discourse users when building a preview for the first time' do
      context 'host' do
        before do
          host_email = client.host(nil).fetch(:email)
          @host = Fabricate(:user, email: host_email)
          @avatar_url = @host.avatar_template_url.gsub('{size}', '120')
        end

        it 'uses the user data when the email matches' do
          webinar_data = webinars.preview(webinar_id).fetch(:host)

          expect(webinar_data[:name]).to eq @host.name
          expect(webinar_data[:avatar_url]).to eq @avatar_url
        end

        it 'uses the user data when the email matches and the webinar does not list that user as a speaker' do
          Fabricate(:webinar, zoom_id: webinar_id)

          webinar_data = webinars.preview(webinar_id).fetch(:host)

          expect(webinar_data[:name]).to eq @host.name
          expect(webinar_data[:avatar_url]).to eq @avatar_url
        end
      end

      context 'speakers' do
        before do
          speaker_email = client.speakers(nil)[:speakers].first[:email]
          @speaker = Fabricate(:user, email: speaker_email)
          @avatar_url = @speaker.avatar_template_url.gsub('{size}', '25')
        end

        it 'uses the user data when email matches' do
          speaker = webinars.preview(webinar_id).fetch(:speakers).first

          expect(speaker[:name]).to eq @speaker.name
          expect(speaker[:avatar_url]).to eq @avatar_url
        end

        it 'uses the user data when the email matches and the webinar does not list that user as a speaker' do
          Fabricate(:webinar, zoom_id: webinar_id)

          speaker = webinars.preview(webinar_id).fetch(:speakers).first

          expect(speaker[:name]).to eq @speaker.name
          expect(speaker[:avatar_url]).to eq @avatar_url
        end
      end
    end
  end

  def webinars
    described_class.new(client)
  end

  def client
    @client ||= FakeZoom.new
  end
end

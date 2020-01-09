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

    it 'includes the panelists data' do
      webinar_data = webinars.preview(webinar_id)

      expect(webinar_data[:panelists]).to be_present
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

      it 'uses the available panelists data' do
        panelist = Fabricate(:user)
        WebinarUser.create!(webinar: @webinar, user: panelist, type: :panelist)

        webinar_data = webinars.preview(webinar_id).fetch(:panelists).first

        expect(webinar_data[:name]).to eq panelist.name
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

        it 'uses the user data when the email matches and the webinar does not list that user as a panelist' do
          Fabricate(:webinar, zoom_id: webinar_id)

          webinar_data = webinars.preview(webinar_id).fetch(:host)

          expect(webinar_data[:name]).to eq @host.name
          expect(webinar_data[:avatar_url]).to eq @avatar_url
        end
      end

      context 'panelists' do
        before do
          panelist_email = client.panelists(nil)[:panelists].first[:email]
          @panelist = Fabricate(:user, email: panelist_email)
          @avatar_url = @panelist.avatar_template_url.gsub('{size}', '25')
        end

        it 'uses the user data when email matches' do
          panelist = webinars.preview(webinar_id).fetch(:panelists).first

          expect(panelist[:name]).to eq @panelist.name
          expect(panelist[:avatar_url]).to eq @avatar_url
        end

        it 'uses the user data when the email matches and the webinar does not list that user as a panelist' do
          Fabricate(:webinar, zoom_id: webinar_id)

          panelist = webinars.preview(webinar_id).fetch(:panelists).first

          expect(panelist[:name]).to eq @panelist.name
          expect(panelist[:avatar_url]).to eq @avatar_url
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

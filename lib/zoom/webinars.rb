# frozen_string_literal: true

module Zoom
  class Webinars
    def initialize(zoom_client)
      @zoom_client = zoom_client
    end

    def preview(webinar_id)
      @webinar = Webinar.find_by(zoom_id: webinar_id)
      @fallback_to_zoom_api = @webinar.nil?

      webinar_data = webinar(webinar_id)
      host = host(webinar_data[:zoom_host_id])
      speakers = speakers(webinar_id)

      { host: host }.merge!(webinar_data, speakers)
    end

    private

    def webinar(webinar_id)
      return zoom_client.webinar(webinar_id) if @fallback_to_zoom_api

      {
        title: @webinar.title,
        starts_at: @webinar.starts_at,
        ends_at: @webinar.ends_at,
        duration: @webinar.duration,
        zoom_host_id: @webinar.zoom_host_id
      }
    end

    def host(host_id)
      host = @webinar&.webinar_users&.detect { |u| u.type.to_sym == :host }&.user
      return host_payload(host) if host

      host_data = zoom_client.host(host_id)
      user = User.find_by_email(host_data[:email])
      return host_data.except(:email) if user.nil?

      host_payload(user)
    end

    def speakers(webinar_id)
      webinar_speakers = @webinar&.webinar_users&.select { |wu| wu.type.to_sym == :speaker }&.map(&:user)
      return speakers_payload(webinar_speakers) if webinar_speakers.present?

      speakers_data = zoom_client.speakers(webinar_id)
      speaker_emails = speakers_data[:speakers].map { |s| s[:email] }.join(',')
      speakers = User.with_email(speaker_emails)
      return speakers_data.except(:email) if speakers.empty?

      speakers_payload(speakers)
    end

    def speakers_payload(speakers)
      {
        speakers: speakers.map do |s|
          {
            name: s.name || s.username,
            avatar_url: s.avatar_template_url.gsub('{size}', '25')
          }
        end,
        speakers_count: speakers.size
      }
    end

    def host_payload(host)
      {
        name: host.name || host.username,
        avatar_url: host.avatar_template_url.gsub('{size}', '120')
      }
    end

    attr_reader :zoom_client
  end
end

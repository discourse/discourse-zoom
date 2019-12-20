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
      return zoom_client.host(host_id) if @fallback_to_zoom_api
      return zoom_client.host(host_id) unless host = @webinar.webinar_users.detect { |u| u.type.to_sym == :host }&.user

      {
        name: host.name || host.username,
        email: host.email,
        avatar_url: host.avatar_template_url.gsub('{size}', '120')
      }
    end

    def speakers(webinar_id)
      return zoom_client.speakers(webinar_id) if @fallback_to_zoom_api
      webinar_users = @webinar.webinar_users.select { |wu| wu.type.to_sym == :speaker }

      {
        speakers: webinar_users.map do |s|
          user = s.user
          {
            name: user.name || host.username,
            email: user.email
          }
        end,
        speakers_count: webinar_users.size
      }
    end

    attr_reader :zoom_client
  end
end

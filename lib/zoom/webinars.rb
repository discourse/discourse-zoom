# frozen_string_literal: true

module Zoom
  class Webinars
    attr_reader :zoom_client

    def initialize(zoom_client)
      @zoom_client = zoom_client
    end

    def all(user)
      response = zoom_client.get("users/#{user.email}/webinars")
      return [] unless response

      result = response[:webinars]&.select do |hash|
        hash[:start_time].in_time_zone.utc > Time.now.utc
      end

      result
    end

    def find(webinar_id)
      webinar_data = zoom_client.webinar(webinar_id)
      webinar_data[:panelists] = panelists(webinar_id)
      webinar_data[:host] = host(webinar_data[:zoom_host_id])
      webinar_data
    end

    private

    def host(host_id)
      host_data = zoom_client.host(host_id)
      user = User.find_by_email(host_data[:email])
      return host_data if user.nil?

      host_payload(user)
    end

    def panelists(webinar_id)
      panelists_data = zoom_client.panelists(webinar_id)
      panelist_emails = panelists_data[:panelists].map { |s| s[:email] }.join(',')
      panelists = User.with_email(panelist_emails)

      if panelists.empty?
        panelists = panelists_data[:panelists].map { |s| { name: s[:name], avatar_url: s[:avatar_url] } }
        return panelists
      end

      panelists_payload(panelists)
    end

    def panelists_payload(panelists)
      {
        panelists: panelists.map do |s|
          {
            name: s.name || s.username,
            avatar_url: s.avatar_template_url.gsub('{size}', '25')
          }
        end,
        panelists_count: panelists.size
      }
    end

    def host_payload(host)
      {
        name: host.name || host.username,
        avatar_url: host.avatar_template_url.gsub('{size}', '120')
      }
    end
  end
end

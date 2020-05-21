# frozen_string_literal: true

module Zoom
  class Webinars
    attr_reader :zoom_client

    RECURRING_WEBINAR_TYPE = 9

    def initialize(zoom_client)
      @zoom_client = zoom_client
    end

    def unmatched(user)
      response = zoom_client.get("users/#{user.email}/webinars?page_size=300")
      return [] unless response

      result = response&.body[:webinars]&.select do |hash|
        hash[:start_time].in_time_zone.utc > Time.now.utc \
          && hash[:type] != RECURRING_WEBINAR_TYPE \
          && Webinar.where(zoom_id: hash[:id]).empty?
      end

      result
    end

    def find(webinar_id)
      webinar_data = zoom_client.webinar(webinar_id)
      return false unless webinar_data[:id]
      webinar_data[:panelists] = panelists(webinar_id)
      webinar_data[:host] = host(webinar_data[:zoom_host_id])

      existing_topic = Webinar.where(zoom_id: webinar_id).first
      webinar_data[:existing_topic] = existing_topic if existing_topic.present?

      webinar_data
    end

    def add_panelist(webinar:, user:)
      response = zoom_client.post("webinars/#{webinar.zoom_id}/panelists",
        panelists: [{
          email: user.email,
          name: user.name.blank? ? user.username : user.name
        }]
      )
      return false if response.status != 201

      WebinarUser.where(user: user, webinar: webinar).destroy_all
      WebinarUser.create!(user: user, webinar: webinar, type: :panelist)
    end

    def remove_panelist(webinar:, user:)
      panelists = zoom_client.panelists(webinar.zoom_id, true)[:body][:panelists]
      matching_panelist = panelists.detect do |panelist|
        panelist[:email] == user.email
      end
      return false unless matching_panelist

      response = zoom_client.delete("webinars/#{webinar.zoom_id}/panelists/#{matching_panelist[:id]}")
      return false if response.status != 204

      WebinarUser.where(user: user, webinar: webinar).destroy_all
    end

    def signature(webinar_id)
      return false unless SiteSetting.zoom_api_key && SiteSetting.zoom_api_secret
      webinar = zoom_client.webinar(webinar_id)
      return false unless webinar[:id]

      role = "0" # regular member role
      ts = (Time.now.to_f * 1000).round(0) - 30000
      msg = Base64.strict_encode64(SiteSetting.zoom_api_key + webinar_id + ts.to_s + role)
      hash = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", SiteSetting.zoom_api_secret, msg))
      Base64.strict_encode64("#{SiteSetting.zoom_api_key}.#{webinar_id}.#{ts.to_s}.#{role}.#{hash}")
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
      panelists.map do |s|
        {
          name: s.name || s.username,
          avatar_url: s.avatar_template_url.gsub('{size}', '25')
        }
      end
    end

    def host_payload(host)
      if SiteSetting.zoom_host_title_override
        field_id = UserField.where(name: SiteSetting.zoom_host_title_override).pluck(:id).first
        title = host.user_fields[field_id.to_s] || ""
      else
        title = host.title
      end
      {
        name: host.name || host.username,
        title: title,
        avatar_url: host.avatar_template_url.gsub('{size}', '120')
      }
    end
  end
end

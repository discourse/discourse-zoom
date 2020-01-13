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
      return false unless webinar_data[:id]
      webinar_data[:panelists] = panelists(webinar_id)
      webinar_data[:host] = host(webinar_data[:zoom_host_id])
      webinar_data
    end

    def add_panelist(webinar:, user:)
      response = zoom_client.post("webinars/#{webinar.zoom_id}/panelists", {
        panelists: [{
          email: user.email,
          name: user.name.blank? ? user.username : user.name
        }]
      })
      return false if response.status != 201

      WebinarUser.where(user: user, webinar: webinar).destroy_all
      WebinarUser.create!(user: user, webinar: webinar, type: :panelist, registration_status: :approved)
    end

    def remove_panelist(webinar:, user:)
      panelists = zoom_client.panelists(webinar.zoom_id, true)[:panelists]
      matching_panelist = panelists.detect { |panelist| panelist[:email] == user.email }
      return false unless matching_panelist

      response = zoom_client.delete("webinars/#{webinar.zoom_id}/panelists/#{matching_panelist[:id]}")
      return false if response.status != 204

      WebinarUser.where(user: user, webinar: webinar).destroy_all
    end

    def register(webinar:, user:)
      attendees = zoom_client.attendees(webinar.zoom_id, true)[:registrants]
      matching_attendee = attendees.detect{ |attendee| attendee[:email] == user.email }
      return register_clean(webinar: webinar, user: user) if !matching_attendee

      response = zoom_client.put("webinars/#{webinar.zoom_id}/registrants/status", {
        action: "approve",
        registrants: [{
          email: matching_attendee[:email],

        }]
      })
      return false if response.status != 204

      WebinarUser.where(user: user, webinar: webinar).update_all(registration_status: :approved)
    end

    def register_clean(webinar:, user:)
      split_name = user.name.split(' ')
      if (split_name.count > 1)
        first_name = split_name.first
        last_name = split_name[1..-1].join(' ')
      else
        first_name = user.username
        last_name = "n/a"
      end

      response = zoom_client.post("webinars/#{webinar.zoom_id}/registrants",
        email: user.email,
        first_name: first_name,
        last_name: last_name
      )

      return false if response.status != 201
      registration_status = case webinar.approval_type
                            when "automatic"
                              :approved
                            when "manual"
                              :pending
                            when "no_registration"
                              :rejected
      end

      webinar.webinar_users.create(
        user: user,
        type: :attendee,
        registration_status: registration_status
      )
    end

    def unregister(webinar:, user:)
      attendees = zoom_client.attendees(webinar.zoom_id, true)[:registrants]
      matching_attendee = attendees.detect{ |attendee| attendee[:email] == user.email }
      return false unless matching_attendee

      response = zoom_client.put("webinars/#{webinar.zoom_id}/registrants/status", {
        action: "cancel",
        registrants: [{
          email: matching_attendee[:email],
          id: matching_attendee[:id]
        }]
      })
      return false if response.status != 204

      WebinarUser.where(user: user, webinar: webinar).update_all(registration_status: :rejected)
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

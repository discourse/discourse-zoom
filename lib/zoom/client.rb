# frozen_string_literal: true

module Zoom
  class Client
    API_URL = 'https://api.zoom.us/v2/'

    def webinar(webinar_id)
      data = get("webinars/#{webinar_id}")

      start_datetime = DateTime.parse(data[:start_time])

      {
        id: webinar_id,
        title: data[:topic],
        starts_at: start_datetime,
        duration: data[:duration],
        ends_at: start_datetime + data[:duration].minutes,
        zoom_host_id: data[:host_id],
        password: data[:password],
        host_video: data[:settings][:host_video],
        panelists_video: data[:settings][:panelists_video],
        approval_type: data[:settings][:approval_type],
        enforce_login: data[:settings][:enforce_login],
        registrants_restrict_number: data[:settings][:registrants_restrict_number],
        meeting_authentication: data[:settings][:meeting_authentication],
        on_demand: data[:settings][:on_demand],
        join_url: data[:settings][:join_url],
      }
    end

    def host(host_id)
      data = get("users/#{host_id}")
      {
        name: "#{data[:first_name]} #{data[:last_name]}",
        email: data[:email],
        avatar_url: data[:pic_url]
      }
    end

    def panelists(webinar_id, raw = false)
      data = get("webinars/#{webinar_id}/panelists")
      return data if raw

      {
        panelists: data[:panelists].map do |s|
          {
            name: s[:name],
            email: s[:email],
            avatar_url: User.default_template(s[:name]).gsub('{size}', '25')
          }
        end,
        panelists_count: data[:total_records]
      }
    end

    def attendees(webinar_id, raw = false)
      data = get("webinars/#{webinar_id}/registrants")
      return data if raw

      {
        attendees: data[:registrants].map do |s|
          {
            name: s[:name],
            email: s[:email],
            avatar_url: User.default_template(s[:name]).gsub('{size}', '25')
          }
        end,
        attendees_count: data[:total_records]
      }
    end

    def get(endpoint)
      result = Excon.get(
        "#{API_URL}#{endpoint}",
        headers: { 'Authorization': "Bearer #{jwt_token}" }
      )

      JSON.parse(result.body, symbolize_names: true)
    end

    def put(endpoint, body)
      Excon.put("#{API_URL}#{endpoint}",
        headers: {
          "Authorization": "Bearer #{jwt_token}",
          "Content-Type": "application/json"
        },
        body: body.to_json
      )
    end

    def post(endpoint, body)
      Excon.post("#{API_URL}#{endpoint}",
        headers: {
          "Authorization": "Bearer #{jwt_token}",
          "Content-Type": "application/json"
        },
        body: body.to_json
      )
    end

    def delete(endpoint)
      result = Excon.delete(
        "#{API_URL}#{endpoint}",
        headers: { 'Authorization': "Bearer #{jwt_token}" }
      )
    end

    def jwt_token()
      payload = {
        iss: SiteSetting.zoom_api_key,
        exp: 1.hour.from_now.to_i
      }

      JWT.encode(payload, SiteSetting.zoom_api_secret, "HS256", typ: "JWT")
    end
  end
end

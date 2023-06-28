# frozen_string_literal: true

module Zoom
  class Client
    API_URL = 'https://api.zoom.us/v2/'

    def webinar(webinar_id, raw = false)
      response = get("webinars/#{webinar_id}")
      return response if raw

      data = response.body
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
      response = get("users/#{host_id}")
      data = response.body
      {
        name: "#{data[:first_name]} #{data[:last_name]}",
        email: data[:email],
        avatar_url: data[:pic_url]
      }
    end

    def panelists(webinar_id, raw = false)
      response = get("webinars/#{webinar_id}/panelists")
      return response if raw

      data = response.body
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

    def get(endpoint)
      response = Excon.get(
        "#{API_URL}#{endpoint}",
        headers: { 'Authorization': "Bearer #{jwt_token}" }
      )
      
      response.body = JSON.parse(response.body, symbolize_names: true) unless response.body.blank?
      response
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

    def jwt_token
      payload = {
        iss: SiteSetting.zoom_sdk_key,
        exp: Time.now.to_i + 3600,
      }

      JWT.encode(payload, SiteSetting.zoom_api_secret)
    end
  end
end

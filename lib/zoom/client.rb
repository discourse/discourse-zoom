# frozen_string_literal: true

module Zoom
  class Client
    API_URL = 'https://api.zoom.us/v2/'

    def webinar(webinar_id)
      data = get("webinars/#{webinar_id}")
      start_datetime = DateTime.parse(data[:start_time])

      {
        title: data[:topic],
        starts_at: start_datetime,
        duration: data[:duration],
        ends_at: start_datetime + data[:duration].minutes,
        zoom_host_id: data[:host_id]
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

    def speakers(webinar_id)
      data = get("webinars/#{webinar_id}/panelists")

      {
        speakers: data[:panelists].map do |s|
          {
            name: s[:name],
            email: s[:email],
            avatar_url: User.default_template(s[:name]).gsub('{size}', '25')
          }
        end,
        speakers_count: data[:total_records]
      }
    end

    private

    def get(endpoint)
      result = Excon.get(
        "#{API_URL}#{endpoint}",
        headers: { 'Authorization': "Bearer #{SiteSetting.zoom_jwt_token}" }
      )

      JSON.parse(result.body, symbolize_names: true)
    end

    def post(endpoint, body)
      Excon.post("#{API_URL}#{endpoint}",
        headers: {
          "Authorization": "Bearer #{SiteSetting.zoom_jwt_token}",
          "Content-Type": "application/json"
        },
        body: body.to_json
      )
    end
  end
end

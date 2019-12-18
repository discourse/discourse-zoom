module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    before_action :ensure_logged_in

    def show
      response = Excon.get("https://api.zoom.us/v2/webinars/#{params[:id]}",
        headers: {
          'Authorization': "Bearer #{SiteSetting.zoom_jwt_token}"
        }
      )
      render json: response.body
    end

    def register
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

      webinar = Webinar.find(params[:webinar_id])
      raise Discourse::NotFound.new unless webinar

      split_name = user.name.split(' ')
      if (split_name.count > 1)
        first_name = split_name.first
        last_name = split_name[1..-1].join(' ')
      else
        first_name = user.name
        last_name = user.username
      end

      response = Excon.post("https://api.zoom.us/v2/webinars/#{webinar.zoom_id}/registrants",
        headers: {
          "Authorization": "Bearer #{SiteSetting.zoom_jwt_token}",
          "Content-Type": "application/json"
        },
        body: { email: user.email, first_name: first_name, last_name: last_name }.to_json
      )

      if response.status == 201
        webinar.webinar_users.create(user: user, type: "attendee")
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end
  end
end

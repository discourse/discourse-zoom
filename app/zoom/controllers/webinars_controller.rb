# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    before_action :ensure_logged_in

    def show
      webinar_id = params[:id].to_s.strip.gsub('-', '')

      render json: Zoom::Webinars.new(Zoom::Client.new).preview(webinar_id)
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


      response = Zoom::Client.post("webinars/#{webinar.zoom_id}/registrants", {
        email: user.email,
        first_name: first_name,
        last_name: last_name
      })

      if response.status == 201
        webinar.webinar_users.create(user: user, type: :attendee)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end
  end
end

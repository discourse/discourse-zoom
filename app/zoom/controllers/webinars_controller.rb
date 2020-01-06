# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    before_action :ensure_logged_in

    def show
      webinar_id = Webinar.sanitize_zoom_id(params[:id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      return render Discourse::NotFound unless webinar

      render_serialized(
        webinar,
        WebinarSerializer,
        rest_serializer: true,
        root: :webinar,
        meta: { attendees: 'user', host: 'user', speakers: 'user' }
      )
    end

    def preview
      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      render json: Zoom::Webinars.new(Zoom::Client.new).fetch(webinar_id)
    end

    def register
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

      webinar = Webinar.find_by(zoom_id: params[:webinar_id])
      raise Discourse::NotFound.new unless webinar

      split_name = user.name.split(' ')
      if (split_name.count > 1)
        first_name = split_name.first
        last_name = split_name[1..-1].join(' ')
      else
        first_name = user.username
        last_name = "n/a"
      end

      response = Zoom::Client.new.post("webinars/#{webinar.zoom_id}/registrants", {
        email: user.email,
        first_name: first_name,
        last_name: last_name
      })

      if response.status == 201
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
        render json: user.webinar_users
      else
        raise Discourse::NotFound.new
      end
    end
  end
end

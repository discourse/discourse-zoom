# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    before_action :ensure_logged_in

    def index
      render json: Zoom::Webinars.new(Zoom::Client.new).all(current_user)
    end

    def show
      webinar_id = Webinar.sanitize_zoom_id(params[:id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      raise Discourse::NotFound.new unless webinar

      render_serialized(
        webinar,
        WebinarSerializer,
        rest_serializer: true,
        root: :webinar,
        meta: { attendees: 'user', host: 'user', panelists: 'user' }
      )
    end

    def destroy
      webinar_id = Webinar.sanitize_zoom_id(params[:id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      raise Discourse::NotFound.new unless webinar

      guardian.ensure_can_edit!(webinar.topic)
      webinar.webinar_users.destroy_all
      webinar.destroy
      render json: success_json
    end

    def add_panelist
      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      raise Discourse::NotFound.new unless webinar

      user = fetch_user_from_params
      raise Discourse::NotFound if user.in? webinar.panelists

      if Zoom::Webinars.new(zoom_client).add_panelist(webinar: webinar, user: user)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    def remove_panelist
      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      raise Discourse::NotFound.new unless webinar

      user = fetch_user_from_params
      raise Discourse::NotFound unless user.in? webinar.panelists

      if Zoom::Webinars.new(zoom_client).remove_panelist(webinar: webinar, user: user)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    def add_to_topic
      topic = Topic.find(params[:topic_id])
      raise Discourse::NotFound.new unless topic

      webinar = WebinarCreator.new(topic.id, params[:webinar][:id], params[:webinar]).run
      raise Discourse::InvalidParameters.new unless webinar

      render json: { zoom_id: webinar.zoom_id }
    end

    def preview
      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      render json: Zoom::Webinars.new(zoom_client).find(webinar_id)
    end

    def register
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      webinar = Webinar.find_by(zoom_id: webinar_id)
      raise Discourse::NotFound.new.new unless webinar

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
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    private

    def zoom_client
      @zoom_client ||= Zoom::Client.new
    end
  end
end

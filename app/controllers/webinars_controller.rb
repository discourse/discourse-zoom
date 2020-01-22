# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    skip_before_action :check_xhr, only: [:sdk]
    before_action :ensure_logged_in
    before_action :ensure_webinar_exists, only: [ :show, :destroy, :add_panelist,
                                                  :remove_panelist, :register, :unregister,
                                                  :signature, :sdk ]

    def index
      render json: Zoom::Webinars.new(Zoom::Client.new).unmatched(current_user)
    end

    def show
      render_serialized(
        webinar,
        WebinarSerializer,
        rest_serializer: true,
        root: :webinar,
        meta: { attendees: 'user', host: 'user', panelists: 'user' }
      )
    end

    def destroy
      guardian.ensure_can_edit!(webinar.topic)
      webinar.webinar_users.destroy_all
      webinar.destroy
      render json: success_json
    end

    def add_panelist
      user = fetch_user_from_params
      guardian.ensure_can_edit!(webinar.topic)
      raise Discourse::NotFound if user.in? webinar.panelists

      if Zoom::Webinars.new(zoom_client).add_panelist(webinar: webinar, user: user)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    def remove_panelist
      user = fetch_user_from_params
      guardian.ensure_can_edit!(webinar.topic)
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

      new_webinar = WebinarCreator.new(topic_id: topic.id, zoom_id: params[:zoom_id]).run
      render json: { id: new_webinar.id }
    end

    def preview
      webinar_id = Webinar.sanitize_zoom_id(params[:webinar_id])
      preview = Zoom::Webinars.new(zoom_client).find(webinar_id)

      render json: preview
    end

    def register
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

      webinar.webinar_users.create(
        user: user,
        type: :attendee
      )
      render json: success_json
    end

    def unregister
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

     webinar.webinar_users.where(
       user: user,
       type: :attendee
     ).destroy_all
     render json: success_json
   end

    def signature
      sig = Zoom::Webinars.new(Zoom::Client.new).signature(webinar.zoom_id)
      if SiteSetting.zoom_send_user_id
        username = "#{current_user.name} (#{current_user.id})"
      else
        username = current_user.name
      end

      render json: {
        api_key: SiteSetting.zoom_api_key,
        email: current_user.email,
        id: webinar.zoom_id,
        signature: sig,
        username: username,
        topic_url: webinar.topic.url
      }
    end

    def sdk
      render layout: 'no_ember'
      false
    end

    def set_video_url
      guardian.ensure_can_edit!(webinar.topic)

      webinar.update(video_url: params[:video_url])
      render json: { video_url: webinar.video_url }
    end

    private

    def ensure_webinar_exists
      Rails.logger.error "webinar missing, params: #{params.inspect}" unless webinar
      raise Discourse::NotFound.new unless webinar
    end

    def webinar
      @webinar ||= Webinar.find(params[:webinar_id] || params[:id])
    end

    def zoom_client
      @zoom_client ||= Zoom::Client.new
    end
  end
end

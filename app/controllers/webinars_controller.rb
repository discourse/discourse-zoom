# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:register]
    skip_before_action :check_xhr, only: [:sdk]
    before_action :ensure_logged_in, except: [:show]
    before_action :ensure_webinar_exists, only: [ :show, :destroy, :add_panelist,
                                                  :remove_panelist, :register, :unregister,
                                                  :signature, :sdk, :update_nonzoom_host, :update_nonzoom_details ]

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

      if webinar.non_zoom_event?
        WebinarUser.where(user: user, webinar: webinar).destroy_all
        WebinarUser.create!(user: user, webinar: webinar, type: :panelist)
        render json: success_json
        return
      end

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

      if webinar.non_zoom_event?
        WebinarUser.where(user: user, webinar: webinar).destroy_all
        render json: success_json
        return
      end

      if Zoom::Webinars.new(zoom_client).remove_panelist(webinar: webinar, user: user)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    def add_to_topic
      topic = Topic.find(params[:topic_id])
      raise Discourse::NotFound.new unless topic

      new_webinar = params[:zoom_start_date] ?
                      WebinarCreator.new(topic_id: topic.id, zoom_id: params[:zoom_id], zoom_start_date: params[:zoom_start_date], zoom_title: params[:zoom_title], user: current_user).run :
                      WebinarCreator.new(topic_id: topic.id, zoom_id: params[:zoom_id]).run

      render json: { id: new_webinar.id }
    end

    def update_nonzoom_host
      user = fetch_user_from_params
      guardian.ensure_can_edit!(webinar.topic)
      raise Discourse::NotFound if user == webinar.host

      if webinar.non_zoom_event?
        WebinarUser.where(user: user, webinar: webinar).destroy_all
        WebinarUser.where(webinar: webinar, type: :host).destroy_all
        WebinarUser.create!(user: user, webinar: webinar, type: :host)
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
    end

    def delete_nonzoom_host
      user = fetch_user_from_params
      guardian.ensure_can_edit!(webinar.topic)
      raise Discourse::NotFound unless user == webinar.host
      raise Discourse::NotFound unless webinar.non_zoom_event?

      WebinarUser.where(user: user, webinar: webinar).destroy_all
      render json: success_json
    end

    def update_nonzoom_details
      params.require(:title)
      params.require(:past_start_date)
      guardian.ensure_can_edit!(webinar.topic)

      if webinar.non_zoom_event?
        webinar.title = params[:title]
        webinar.starts_at = params[:past_start_date]
        webinar.save!
        render json: success_json
      else
        raise Discourse::NotFound.new
      end
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
        username = "#{current_user.name || current_user.username} (#{current_user.id})"
      else
        username = current_user.name || current_user.username
      end

      render json: {
        sdk_key: SiteSetting.zoom_sdk_key,
        email: current_user.email,
        id: webinar.zoom_id,
        signature: sig,
        username: username,
        topic_url: webinar.topic.url,
        password: webinar.password
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

    def watch
      user = fetch_user_from_params
      guardian.ensure_can_edit!(user)

      DiscourseEvent.trigger(:webinar_participant_watched, webinar, user)
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

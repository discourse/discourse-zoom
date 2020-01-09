# frozen_string_literal: true
module Zoom
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :ensure_webhook_authenticity

    HANDLED_EVENTS = [
      "webinar.updated",
      "webinar.registration_approved",
      "webinar.registration_created",
      "webinar.registration_cancelled",
      "webinar.registration_denied"
    ]

    def webinars
      event = webinar_params[:event]
      send(handler_for(event)) if HANDLED_EVENTS.include?(event)

      render json: success_json
    end

    private

    def handler_for(event)
      event.gsub(".", "_").to_sym
    end

    def webinar_updated
      raise Discourse::NotFound unless old_webinar
      filter_old_webhook_event

      old_webinar.update_from_zoom(webinar_params.dig(:payload, :object))
    end

    # Registration hooks

    def webinar_registration_created
      raise Discourse::NotFound unless webinar

      registration_status = registrant[:status] == 'approved' ? :approved : :pending
      webinar_user = WebinarUser.find_or_create_by(user: user, webinar: webinar)
      webinar_user.update(type: :attendee, registration_status: registration_status)
    end

    def webinar_registration_approved
      raise Discourse::NotFound unless webinar

      WebinarUser.find_or_create_by(webinar: webinar, user: user).update(type: :attendee, registration_status: :approved)
    end

    def webinar_registration_cancelled
      raise Discourse::NotFound unless webinar

      WebinarUser.find_or_create_by(webinar: webinar, user: user).update(type: :attendee, registration_status: :rejected)
    end

    def webinar_registration_denied
      webinar_registration_cancelled
    end

    def ensure_webhook_authenticity
      if request.headers["Authorization"] != SiteSetting.zoom_verification_token
        raise Discourse::InvalidAccess.new
      end
    end

    def user
      @user ||= begin
        user = User.find_by_email(registrant[:email])
        return user if user

        stage_user
      end
    end

    def stage_user
      User.create!(
        email: registrant[:email],
        username: UserNameSuggester.suggest(registrant[:email]),
        name: User.suggest_name(registrant[:email]),
        staged: true
      )
    end

    def old_webinar
      @weninar ||= begin
        zoom_id = webinar_params.fetch(:payload, {}).fetch(:old_object, {}).fetch(:id, {})
        return nil unless zoom_id

        Webinar.find_by(zoom_id: zoom_id)
      end
    end

    def filter_old_webhook_event
      payload_data = webinar_params[:payload].to_h
      payload = MultiJson.dump(payload_data)

      ::ZoomWebinarWebhookEvent.create!(
        event: webinar_params[:event],
        payload: payload,
        webinar_id: payload_data.dig(:object, :id)&.to_i,
        zoom_timestamp: payload_data[:time_stamp]&.to_i
      )
    end

    def webinar
      @weninar ||= begin
        zoom_id = webinar_params.fetch(:payload, {}).fetch(:object, {}).fetch(:id, {})
        return nil unless zoom_id

        Webinar.find_by(zoom_id: zoom_id)
      end
    end

    def registrant
      @registrant ||= webinar_params.fetch(:payload, {}).fetch(:object, {}).fetch(:registrant, {})
    end

    def webinar_params
      params.require(:webhook).permit(:event, payload: {})
    end
  end
end

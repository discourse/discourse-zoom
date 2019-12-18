module Zoom
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :ensure_webhook_authenticity

    HANDLED_EVENTS = [
      "webinar.registration_approved",
      "webinar.registration_created",
      "webinar.registration_cancelled",
      "webinar.registration_denied"
    ]

    def webinars
      event = webinar_params[:event]
      send(event_to_method(event)) if HANDLED_EVENTS.include?(event)

      render json: success_json
    end

    private

    def event_to_method(event)
      event.gsub(".", "_").to_sym
    end

    def webinar_registration_created
      webinar = find_webinar
      return unless webinar

      user = User.find_by_email(registrant[:email])
      unless user
        user = User.create!(
          email: registrant[:email],
          username: UserNameSuggester.suggest(registrant[:email]),
          name: User.suggest_name(registrant[:email]),
          staged: true
        )
      end
      WebinarUser.find_or_create_by(user: user, webinar: webinar, type: "attendee")
    end

    def webinar_registration_approved
      webinar_registration_created
    end

    def webinar_registration_cancelled
      webinar = find_webinar
      return unless webinar

      user = User.find_by_email(registrant[:email])
      return unless user

      WebinarUser.where(webinar: webinar, user: user).destroy_all
    end

    def webinar_registration_denied
      webinar_registration_cancelled
    end

    def ensure_webhook_authenticity
      if request.headers["Authorization"] != SiteSetting.zoom_verification_token
        raise Discourse::InvalidAccess.new
      end
    end

    def webinar_params
      params.require(:webhook).permit(:event, payload: {})
    end

    def find_webinar
      zoom_id = webinar_params.fetch(:payload, {}).fetch(:object, {}).fetch(:id, {})
      return nil unless zoom_id

      Webinar.find_by(zoom_id: zoom_id)
    end

    def registrant
      @registrant ||= webinar_params.fetch(:payload, {}).fetch(:object, {}).fetch(:registrant, {})
    end
  end
end

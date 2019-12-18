module Zoom
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :ensure_webhook_authenticity

    def webinars
      event = webinar_params[:event].gsub(".", "_").to_sym
      if self.respond_to? event
        send(event)
      else
        render json: success_json
      end
    end

    private

    def webinar_registration_created

    end

    def ensure_webhook_authenticity
      if request.headers["Authorization"] != SiteSetting.zoom_verification_token
        raise Discourse::InvalidAccess.new
      end
    end

    def webinar_params
      params.permit(:event, payload: {})
    end
  end
end

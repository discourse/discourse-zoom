# frozen_string_literal: true
module Zoom
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token,
                       :redirect_to_login_if_required
    before_action :filter_unhandled,
                  :ensure_webhook_authenticity,
                  :filter_expired_event

    HANDLED_EVENTS = %w[
      webinar.updated
      webinar.started
      webinar.ended
      webinar.participant_joined
      webinar.participant_left
      endpoint.url_validation
    ]

    def webinars
      request_params = webinar_params
      if request_params[:event] == "endpoint.url_validation"
        secret = SiteSetting.zoom_webhooks_secret_token
        encrypted_token =
          OpenSSL::HMAC.hexdigest(
            OpenSSL::Digest.new("sha256"),
            secret,
            JSON.parse(request.body.read, symbolize_names: true)[:payload][
              :plainToken
            ]
          )
        response.status = 200
        response.body = {
          plainToken: request_params[:payload][:plain_token],
          encryptedToken: encrypted_token
        }.to_json

        render json: response.body
        return
      else
        send(handler_for(request_params[:event]))
      end

      render json: success_json
    end

    private

    def handler_for(event)
      event.gsub(".", "_").to_sym
    end

    def webinar_updated
      raise Discourse::NotFound unless old_webinar

      old_webinar.update_from_zoom(webinar_params.dig(:payload, :object))
    end

    def webinar_started
      raise Discourse::NotFound unless webinar

      webinar.update(status: :started)
    end

    def webinar_ended
      raise Discourse::NotFound unless webinar

      webinar.update(status: :ended)
    end

    def webinar_participant_joined
      DiscourseEvent.trigger(
        :webinar_participant_joined,
        webinar,
        webinar_params
      )
    end

    def webinar_participant_left
      DiscourseEvent.trigger(:webinar_participant_left, webinar, webinar_params)
    end

    def ensure_webhook_authenticity
      request_params = webinar_params
      message =
        "v0:#{request.headers["x-zm-request-timestamp"]}:#{request.body.read}"

      secret = SiteSetting.zoom_webhooks_secret_token

      calculated_hash = OpenSSL::HMAC.hexdigest("SHA256", secret, message)
      signature = "v0=#{calculated_hash}"
      request_signature = request.headers["x-zm-signature"]

      if !ActiveSupport::SecurityUtils.secure_compare(
           signature,
           request_signature
         )
        raise Discourse::InvalidAccess.new
      end
    end

    def user
      @user ||=
        begin
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

    def filter_unhandled
      unless HANDLED_EVENTS.include?(webinar_params[:event])
        raise Discourse::NotFound
      end
    end

    def filter_expired_event
      payload_data = webinar_params[:payload].to_h
      payload = MultiJson.dump(payload_data)

      new_event =
        ::ZoomWebinarWebhookEvent.new(
          event: webinar_params[:event],
          payload: payload,
          webinar_id: payload_data.dig(:object, :id)&.to_i,
          zoom_timestamp: payload_data[:time_stamp]&.to_i
        )

      if new_event.zoom_timestamp
        later_events =
          ::ZoomWebinarWebhookEvent.where(
            %Q(event = '#{new_event.event}'
                    AND webinar_id = #{new_event.webinar_id}
                    AND zoom_timestamp >= #{new_event.zoom_timestamp})
          )
        raise Discourse::NotFound if later_events.any?
        new_event.save!
      end

      true
    end

    def old_webinar
      @old_weninar ||= find_webinar_from(:old_object)
    end

    def webinar
      @weninar ||= find_webinar_from(:object)
    end

    def find_webinar_from(key)
      zoom_id = webinar_params.fetch(:payload, {}).fetch(key, {}).fetch(:id, {})
      return nil unless zoom_id

      Webinar.find_by(zoom_id: zoom_id)
    end

    def registrant
      @registrant ||=
        webinar_params
          .fetch(:payload, {})
          .fetch(:object, {})
          .fetch(:registrant, {})
    end

    def webinar_params
      params.require(:webhook).permit(:event, :event_ts, payload: {})
    end
  end
end

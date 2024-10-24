# frozen_string_literal: true
module Zoom
  class OAuthClient
    OAUT_URL = "https://zoom.us/oauth/token"

    def initialize(api_url, end_point, authorization = nil)
      @api_url = api_url
      @end_point = end_point
      @max_tries = 5
      @tries = 0

      if authorization
        @authorization = authorization
      else
        @oauth = true
        @authorization =
          (
            if SiteSetting.s2s_oauth_token.empty?
              get_oauth
            else
              SiteSetting.s2s_oauth_token
            end
          )
      end
    end

    def get
      response = send_request(:get)
      self.parse_response_body response
    end

    def post(body)
      send_request(:post, body)
    end

    def delete
      send_request(:delete)
    end

    private

    def send_request(method, body = nil)
      response =
        Excon.send(
          method,
          "#{@api_url}#{@end_point}",
          headers: {
            Authorization: "Bearer #{@authorization}",
            "Content-Type": "application/json",
          },
          body: body&.to_json,
        )

      if [400, 401].include?(response.status) && @tries < @max_tries
        get_oauth
        response = send_request(method, body)
      elsif [400, 401].include?(response.status) && @tries == @max_tries
        self.parse_response_body(response)
        # This code 200 is a code sent by Zoom not the request status
        if response&.body&.dig(:code) == 200
          ProblemCheckTracker["s2s_webinar_subscription"].problem!(
            details: {
              message: response.body[:message],
            },
          )
        end

        authorization_invalid
      end

      log("Zoom verbose log:\n API error = #{response.inspect}") if response.status != 200

      if response&.body.present?
        result = JSON.parse(response.body)
        meeting_not_found if (response.status) == 404 && result["code"] == 3001
        log("Zoom verbose log:\n API result = #{result.inspect}")
      end
      response
    end

    def parse_response_body(response)
      response.body = JSON.parse(response.body, symbolize_names: true) if response.body.present?
      response
    end

    private

    def log(message)
      Rails.logger.warn(message) if SiteSetting.discourse_zoom_plugin_verbose_logging
    end

    def get_oauth
      @tries += 1
      credentials = "#{SiteSetting.zoom_s2s_client_id}:#{SiteSetting.zoom_s2s_client_secret}"
      encoded_credentials = Base64.strict_encode64(credentials)

      body = { grant_type: "account_credentials", account_id: SiteSetting.zoom_s2s_account_id }
      body = URI.encode_www_form(body)

      response =
        Excon.post(
          "#{OAUT_URL}?#{body}",
          headers: {
            Authorization: "Basic  #{encoded_credentials}",
            "Content-Type": "application/json",
          },
        )

      response.body = JSON.parse(response.body, symbolize_names: true) if response.body.present?

      if response.status == 200
        SiteSetting.s2s_oauth_token = response.body[:access_token]
        @authorization = response.body[:access_token]
      end
    end

    def authorization_invalid(custom_message = nil)
      custom_message = "s2s_oauth_authorization" if @oauth

      raise Discourse::InvalidAccess.new(
              "zoom_plugin_errors",
              SiteSetting.s2s_oauth_token,
              custom_message: "zoom_plugin_errors.#{custom_message}",
            )
    end

    def meeting_not_found
      raise Discourse::NotFound.new(
              I18n.t("zoom_plugin_errors.meeting_not_found"),
              custom_message: "zoom_plugin_errors.meeting_not_found",
            )
    end
  end
end

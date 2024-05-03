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
        authorization_invalid
      end

      log("Zoom verbose log:\n API error = #{response.inspect}") if response.status != 200

      if response && !response&.body.empty?
        result = JSON.parse(response.body, symbolize_names: true)
        log("Zoom verbose log:\n API result = #{result.inspect}")
      end
      response
    end

    def parse_response_body(response)
      response.body = JSON.parse(response.body, symbolize_names: true) unless response.body.blank?
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

      response.body = JSON.parse(response.body, symbolize_names: true) unless response.body.blank?

      if response.status == 200
        SiteSetting.s2s_oauth_token = response.body[:access_token]
        @authorization = response.body[:access_token]
      end
    end

    def authorization_invalid
      if @oauth
        custom_mesasge =
          "s2s_
      oauth_authorization"
      else
        custom_mesasge = "custom_authorization"
      end

      raise Discourse::InvalidAccess.new(
              "zoom_plugin_authorization_invalid",
              SiteSetting.s2s_oauth_token,
              custom_message: "zoom_plugin_authorization_invalid.#{custom_mesasge}",
            )
    end
  end
end

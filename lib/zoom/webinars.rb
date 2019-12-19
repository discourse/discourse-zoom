# frozen_string_literal: true

module Zoom
  class Webinars
    def initialize(zoom_client)
      @zoom_client = zoom_client
    end

    def preview(webinar_id)
      webinar_data = zoom_client.webinar(webinar_id)
      host = zoom_client.host(webinar_data[:host_id])
      speakers = zoom_client.speakers(webinar_id)

      { host: host }.merge!(webinar_data, speakers)
    end

    private

    attr_reader :zoom_client
  end
end

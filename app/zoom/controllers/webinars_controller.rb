module Zoom
  class WebinarsController < ApplicationController
    def show
      response = Excon.get("https://api.zoom.us/v2/webinars/#{params[:id]}",
        headers: {
          'Authorization': "Bearer #{SiteSetting.zoom_jwt_token}"
        }
      )
      render json: response.body
    end
  end
end

# frozen_string_literal: true

module Zoom
  class WebinarsController < ApplicationController
    def show
      render json: Zoom::Webinars.new(Zoom::Client.new).preview(params[:id])
    end
  end
end

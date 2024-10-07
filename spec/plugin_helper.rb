# frozen_string_literal: true

require_relative "responses/zoom_api_stubs"

RSpec.configure do |config|
  config.include ZoomApiStubs
end

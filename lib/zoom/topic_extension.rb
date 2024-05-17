# frozen_string_literal: true

module Zoom
  module TopicExtension
    extend ActiveSupport::Concern

    prepended { has_one :webinar }
  end
end

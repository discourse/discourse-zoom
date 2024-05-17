# frozen_string_literal: true

module Zoom
  module UserExtension
    extend ActiveSupport::Concern

    prepended { has_many :webinar_users }
  end
end

# frozen_string_literal: true

# name: discourse-zoom
# about: Integrate Zoom events in Discourse.
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse-org/discourse-zoom

enabled_site_setting :zoom_enabled

after_initialize do
  [
    "../app/models/webinar",
  ].each { |path| require File.expand_path(path, __FILE__) }

  module ::Zoom
    PLUGIN_NAME ||= "discourse-zoom".freeze

    class Engine < ::Rails::Engine
      engine_name Zoom::PLUGIN_NAME
      isolate_namespace Zoom
    end
  end

  require_dependency "application_controller"

  class Zoom::WebinarsController < ::ApplicationController
    requires_plugin Zoom::PLUGIN_NAME

    before_action :ensure_logged_in
  end

  Zoom::Engine.routes.draw do
    resources :webinars
  end

  Discourse::Application.routes.append do
    mount ::Zoom::Engine, at: "/zoom"
  end
end
# frozen_string_literal: true

# name: discourse-zoom
# about: Integrate Zoom events in Discourse.
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse-org/discourse-zoom

enabled_site_setting :zoom_enabled
register_asset "stylesheets/desktop/webinar-builder.scss", :desktop
register_asset "stylesheets/desktop/webinar-details.scss", :desktop

after_initialize do
  [
    "../lib/zoom/webinars",
    "../lib/zoom/client",
    "../app/zoom/controllers/webinars_controller",
    "../app/zoom/controllers/webhooks_controller",
    "../app/models/webinar",
    "../app/models/webinar_user"
  ].each { |path| require File.expand_path(path, __FILE__) }

  module ::Zoom
    PLUGIN_NAME ||= "discourse-zoom".freeze

    class Engine < ::Rails::Engine
      engine_name Zoom::PLUGIN_NAME
      isolate_namespace Zoom
    end
  end

  Zoom::Engine.routes.draw do
    resources :webinars, only: [:show] do
      put 'register/:username' => 'webinars#register'
    end
    post '/webhooks/webinars' => 'webhooks#webinars'
  end

  Discourse::Application.routes.append do
    mount ::Zoom::Engine, at: "/zoom"
  end
end

# frozen_string_literal: true

# name: discourse-zoom
# about: Integrate Zoom events in Discourse.
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse-org/discourse-zoom

enabled_site_setting :zoom_enabled
register_asset "stylesheets/desktop/webinar-builder.scss", :desktop
register_asset "stylesheets/desktop/webinar-banner.scss", :desktop
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

  require_dependency 'topic'
  class ::Topic
    has_one :webinar
  end

  require_dependency 'topic_view'
  class ::TopicView
    def webinar
      topic.webinar
    end
  end

  add_to_serializer(:topic_view, :webinar) { object.webinar }

  add_permitted_post_create_param(:zoom_webinar_id)
  add_permitted_post_create_param(:zoom_webinar_attributes, :hash)
  add_permitted_post_create_param(:zoom_webinar_host, :hash)
  add_permitted_post_create_param(:zoom_webinar_speakers, :array)

  NewPostManager.add_handler do |manager|
    zoom_id = manager.args[:zoom_webinar_id]
    next unless zoom_id

    result = manager.perform_create_post
    if result.success?
      topic_id = result.post.topic_id
      attributes = manager.args[:zoom_webinar_attributes]
      Webinar.create!(
        topic_id: topic_id,
        zoom_id: zoom_id,
        title: attributes[:title],
        starts_at: attributes[:starts_at],
        ends_at: attributes[:ends_at],
        duration: attributes[:duration],
        zoom_host_id: attributes[:zoom_host_id],
      )
    end

    result
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

# frozen_string_literal: true

# name: discourse-zoom
# about: Integrate Zoom events in Discourse.
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse-org/discourse-zoom

enabled_site_setting :zoom_enabled
register_asset "stylesheets/common/zoom.scss"
register_asset "stylesheets/desktop/webinar-picker.scss"
register_asset "stylesheets/desktop/webinar-banner.scss"
register_asset "stylesheets/desktop/webinar-details.scss"

register_svg_icon "far-check-circle"
register_svg_icon "video"

after_initialize do
  [
    "../app/models/webinar",
    "../app/models/webinar_user",
    "../lib/zoom/webinars",
    "../lib/zoom/client",
    "../lib/zoom/webinar_creator",
    "../app/zoom/controllers/webinars_controller",
    "../app/zoom/controllers/webhooks_controller",
    "../app/serializers/webinar_serializer",
  ].each { |path| require File.expand_path(path, __FILE__) }

  module ::Zoom
    PLUGIN_NAME ||= "discourse-zoom".freeze

    class Engine < ::Rails::Engine
      engine_name Zoom::PLUGIN_NAME
      isolate_namespace Zoom
    end
  end

  require_dependency 'user'
  class ::User
    has_many :webinar_users
    # has_many :webinars, through: :webinar_users
  end

  require_dependency 'topic'
  class ::Topic
    has_one :webinar
  end

  add_to_serializer(:topic_view, :webinar) { object.topic.webinar }
  add_to_serializer(:current_user, :webinar_registrations) { object.webinar_users }

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
      Zoom::WebinarCreator.new(topic_id, zoom_id, attributes).run
    end

    result
  end

  Zoom::Engine.routes.draw do
    resources :webinars, only: [:show, :index, :destroy] do
      put 'register/:username' => 'webinars#register'
      get 'preview' => 'webinars#preview'
    end
    put 't/:topic_id/webinars/:webinar_id' => 'webinars#add_to_topic'

    post '/webhooks/webinars' => 'webhooks#webinars'
  end

  Discourse::Application.routes.append do
    mount ::Zoom::Engine, at: "/zoom"
  end
end

# frozen_string_literal: true

# name: discourse-zoom
# about: Integrate Zoom events in Discourse.
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse/discourse-zoom

enabled_site_setting :zoom_enabled
register_asset "stylesheets/common/zoom.scss"
register_asset "stylesheets/common/webinar-picker.scss"
register_asset "stylesheets/common/webinar-details.scss"

register_svg_icon "far-check-circle"
register_svg_icon "far-calendar-alt"
register_svg_icon "video"

after_initialize do
  [
    "../app/models/webinar",
    "../app/models/webinar_user",
    "../app/models/zoom_webinar_webhook_event",
    "../lib/webinars",
    "../lib/client",
    "../lib/webinar_creator",
    "../app/controllers/webinars_controller",
    "../app/controllers/webhooks_controller",
    "../app/serializers/host_serializer",
    "../app/serializers/webinar_serializer",
    "../app/jobs/scheduled/send_webinar_reminders.rb"
  ].each { |path| require File.expand_path(path, __FILE__) }

  module ::Zoom
    PLUGIN_NAME ||= "discourse-zoom".freeze

    class Engine < ::Rails::Engine
      engine_name Zoom::PLUGIN_NAME
      isolate_namespace Zoom
    end
  end

  reloadable_patch do |plugin|
    require_dependency 'user'
    class ::User
      has_many :webinar_users
      # has_many :webinars, through: :webinar_users
    end

    require_dependency 'topic'
    class ::Topic
      has_one :webinar
    end
  end

  add_to_serializer(:topic_view, :webinar) { object.topic.webinar }
  add_to_serializer(:current_user, :webinar_registrations) { object.webinar_users }

  add_permitted_post_create_param(:zoom_id)
  add_permitted_post_create_param(:zoom_webinar_title)
  add_permitted_post_create_param(:zoom_webinar_start_date)

  NewPostManager.add_handler do |manager|
    next if !manager.args[:zoom_id]

    result = manager.perform_create_post
    if result.success? && zoom_id = manager.args[:zoom_id]
      zoom_start_date = manager.args[:zoom_webinar_start_date]
      zoom_title = manager.args[:zoom_webinar_title]
      topic_id = result.post.topic_id

      Zoom::WebinarCreator.new(topic_id: topic_id, zoom_id: zoom_id, zoom_start_date: zoom_start_date, zoom_title: zoom_title, user: manager.user).run
    end

    result
  end

  Zoom::Engine.routes.draw do
    resources :webinars, only: [:show, :index, :destroy] do
      put 'attendees/:username' => 'webinars#register', constraints: { username: RouteFormat.username, format: :json }
      put 'attendees/:username/watch' => 'webinars#watch', constraints: { username: RouteFormat.username, format: :json }
      delete 'attendees/:username' => 'webinars#unregister', constraints: { username: RouteFormat.username, format: :json }
      put 'panelists/:username' => 'webinars#add_panelist', constraints: { username: RouteFormat.username, format: :json }
      delete 'panelists/:username' => 'webinars#remove_panelist', constraints: { username: RouteFormat.username, format: :json }
      put 'video_url' => 'webinars#set_video_url'
      get 'preview' => 'webinars#preview'
      get 'sdk' => 'webinars#sdk'
      get 'signature' => 'webinars#signature'
    end
    put 't/:topic_id/webinars/:zoom_id' => 'webinars#add_to_topic'

    post '/webhooks/webinars' => 'webhooks#webinars'
  end

  Discourse::Application.routes.append do
    mount ::Zoom::Engine, at: "/zoom"
    get "topics/webinar-registrations/:username" => "list#zoom_webinars", as: "topics_zoom_webinars", constraints: { username: ::RouteFormat.username }
  end

  require_dependency 'list_controller'
  class ::ListController
    generate_message_route(:zoom_webinars)
  end

  add_to_class(:topic_query, :list_zoom_webinars) do |user|
    list = joined_topic_user.joins(webinar: :webinar_users)
      .where("webinar_users.user_id = ?", user.id.to_s)
      .order("webinars.starts_at DESC")

    create_list(:webinars, {}, list)
  end

  ::ActionController::Base.prepend_view_path File.expand_path("../app/views", __FILE__)
end

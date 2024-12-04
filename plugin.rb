# frozen_string_literal: true

# name: discourse-zoom
# about: Integrates Zoom webinars into Discourse.
# meta_topic_id: 142711
# version: 0.0.1
# authors: Penar Musaraj, Roman Rizzi, Mark VanLandingham
# url: https://github.com/discourse/discourse-zoom

enabled_site_setting :zoom_enabled
register_asset "stylesheets/common/zoom.scss"
register_asset "stylesheets/common/webinar-picker.scss"
register_asset "stylesheets/common/webinar-details.scss"

register_svg_icon "far-circle-check"
register_svg_icon "far-calendar-days"
register_svg_icon "video"

after_initialize do
  require_relative "app/services/problem_check/s2s_webinar_subscription.rb"
  register_problem_check ProblemCheck::S2sWebinarSubscription
  module ::Zoom
    PLUGIN_NAME ||= "discourse-zoom".freeze

    class Engine < ::Rails::Engine
      engine_name Zoom::PLUGIN_NAME
      isolate_namespace Zoom
    end
  end

  require_relative "app/models/webinar"
  require_relative "app/models/webinar_user"
  require_relative "app/models/zoom_webinar_webhook_event"
  require_relative "lib/webinars"
  require_relative "lib/client"
  require_relative "lib/oauth_client"
  require_relative "lib/webinar_creator"
  require_relative "app/controllers/webinars_controller"
  require_relative "app/controllers/webhooks_controller"
  require_relative "app/serializers/host_serializer"
  require_relative "app/serializers/webinar_serializer"
  require_relative "app/jobs/scheduled/send_webinar_reminders"
  require_relative "lib/zoom/user_extension"
  require_relative "lib/zoom/topic_extension"

  reloadable_patch do |plugin|
    User.prepend(Zoom::UserExtension)
    Topic.prepend(Zoom::TopicExtension)
  end

  add_to_serializer(:topic_view, :webinar) do
    WebinarSerializer.new(object.topic.webinar, root: false).as_json
  end

  add_to_serializer(:current_user, :webinar_registrations) do
    object.webinar_users.as_json(only: %i[user_id type webinar_id])
  end

  add_permitted_post_create_param(:zoom_id)
  add_permitted_post_create_param(:zoom_webinar_title)
  add_permitted_post_create_param(:zoom_webinar_start_date)

  on(:post_created) do |post, opts, user|
    if opts[:zoom_id] && post.is_first_post?
      zoom_start_date = opts[:zoom_webinar_start_date]
      zoom_title = opts[:zoom_webinar_title]

      Zoom::WebinarCreator.new(
        topic_id: post.topic_id,
        zoom_id: opts[:zoom_id],
        zoom_start_date: zoom_start_date,
        zoom_title: zoom_title,
        user: user,
      ).run
    end
  end

  Zoom::Engine.routes.draw do
    resources :webinars, only: %i[show index destroy] do
      put "attendees/:username" => "webinars#register",
          :constraints => {
            username: RouteFormat.username,
            format: :json,
          }
      put "attendees/:username/watch" => "webinars#watch",
          :constraints => {
            username: RouteFormat.username,
            format: :json,
          }
      delete "attendees/:username" => "webinars#unregister",
             :constraints => {
               username: RouteFormat.username,
               format: :json,
             }
      put "panelists/:username" => "webinars#add_panelist",
          :constraints => {
            username: RouteFormat.username,
            format: :json,
          }
      delete "panelists/:username" => "webinars#remove_panelist",
             :constraints => {
               username: RouteFormat.username,
               format: :json,
             }
      put "nonzoom_host/:username" => "webinars#update_nonzoom_host",
          :constraints => {
            username: RouteFormat.username,
            format: :json,
          }
      delete "nonzoom_host/:username" => "webinars#delete_nonzoom_host",
             :constraints => {
               username: RouteFormat.username,
               format: :json,
             }
      put "nonzoom_details" => "webinars#update_nonzoom_details", :constraints => { format: :json }
      put "video_url" => "webinars#set_video_url"
      get "preview" => "webinars#preview"
      get "sdk" => "webinars#sdk"
      get "signature" => "webinars#signature"
    end
    put "t/:topic_id/webinars/:zoom_id" => "webinars#add_to_topic"

    post "/webhooks/webinars" => "webhooks#webinars"
  end

  Discourse::Application.routes.append do
    mount ::Zoom::Engine, at: "/zoom"
    get "topics/webinar-registrations/:username" => "list#zoom_webinars",
        :as => "topics_zoom_webinars",
        :constraints => {
          username: ::RouteFormat.username,
        }
  end

  ListController.generate_message_route(:zoom_webinars)

  add_to_class(:topic_query, :list_zoom_webinars) do |user|
    list =
      joined_topic_user
        .joins(webinar: :webinar_users)
        .where("webinar_users.user_id = ?", user.id.to_s)
        .order("webinars.starts_at DESC")

    create_list(:webinars, {}, list)
  end

  extend_content_security_policy(script_src: ["'unsafe-eval'"])

  ::ActionController::Base.prepend_view_path File.expand_path("../app/views", __FILE__)
end

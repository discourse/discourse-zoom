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
    "../app/models/webinar",
    "../app/models/webinar_user",
    "../lib/zoom/webinars",
    "../lib/zoom/client",
    "../app/zoom/controllers/webinars_controller",
    "../app/zoom/controllers/webhooks_controller",
    "../app/serializers/webinar_serializer"
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

  require_dependency 'topic_view'
  class ::TopicView
    def webinar
      topic.webinar
    end
  end

  add_to_serializer(:topic_view, :webinar) { object.webinar }
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
      webinar = Webinar.create!(
        topic_id: topic_id,
        zoom_id: Webinar.sanitize_zoom_id(zoom_id),
        title: attributes[:title],
        starts_at: attributes[:starts_at],
        ends_at: attributes[:ends_at],
        duration: attributes[:duration],
        zoom_host_id: attributes[:zoom_host_id],
        password: attributes[:password],
        host_video: attributes[:host_video],
        panelists_video: attributes[:panelists_video],
        approval_type: attributes[:approval_type].to_i,
        enforce_login: attributes[:enforce_login],
        registrants_restrict_number: attributes[:registrants_restrict_number],
        meeting_authentication: attributes[:meeting_authentication],
        on_demand: attributes[:on_demand],
        join_url: attributes[:join_url],
      )
      host_data = Zoom::Client.new.host(attributes[:zoom_host_id])
      user = User.find_by_email(host_data[:email])
      unless user
        user = User.create!(
          email: host_data[:email],
          username: UserNameSuggester.suggest(host_data[:email]),
          name: User.suggest_name(host_data[:email]),
          staged: true
        )
      end
      WebinarUser.find_or_create_by(user: user, webinar: webinar, type: :host, registration_status: :approved)
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

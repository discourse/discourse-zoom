# frozen_string_literal: true

module Zoom
  class WebinarCreator
    def initialize(
      topic_id:,
      zoom_id:,
      zoom_start_date: nil,
      zoom_title: nil,
      user: nil
    )
      @topic_id = topic_id
      @zoom_id = Webinar.sanitize_zoom_id(zoom_id)
      @zoom_start_date = zoom_start_date
      @zoom_title = zoom_title
      @zoom_client = Zoom::Client.new
      @current_user = user
    end

    def run
      nonzoom_webinar = @zoom_start_date.present?

      webinar = Webinar.new
      if nonzoom_webinar
        webinar.attributes = {
          starts_at: @zoom_start_date,
          title: @zoom_title,
          zoom_id: @zoom_id,
          status: 2 # marks past event as ended
        }
        user = @current_user
      else
        attributes = @zoom_client.webinar(@zoom_id, true).body
        webinar.attributes = webinar.convert_attributes_from_zoom(attributes)

        host_data = @zoom_client.host(attributes[:host_id])
        user = User.find_by_email(host_data[:email])
      end

      webinar.topic_id = @topic_id
      webinar.save!

      unless user
        user =
          User.create!(
            email: host_data[:email],
            username: UserNameSuggester.suggest(host_data[:email]),
            name: User.suggest_name(host_data[:email]),
            staged: true
          )
      end
      WebinarUser.find_or_create_by(user: user, webinar: webinar, type: :host)
      register_panelists(webinar) unless nonzoom_webinar
      webinar
    end

    private

    def register_panelists(webinar)
      @zoom_client.panelists(webinar.zoom_id, true).body[
        :panelists
      ].each do |attrs|
        user = User.with_email(Email.downcase(attrs[:email])).first
        if !user
          user =
            User.create!(
              email: attrs[:email],
              username: UserNameSuggester.suggest(attrs[:email]),
              name: User.suggest_name(attrs[:email]),
              staged: true
            )
        end

        existin_records = WebinarUser.where(webinar: webinar, user: user)
        if existin_records.any?
          existin_records.update_all(type: :panelist)
        else
          WebinarUser.create!(webinar: webinar, user: user, type: :panelist)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Zoom
  class WebinarCreator
    def initialize(topic_id, zoom_id, attrs)
      @topic_id = topic_id
      @zoom_id = zoom_id
      @attrs = attrs
      @zoom_client = Zoom::Client.new
    end

    def run
      webinar = Webinar.create!(
        topic_id: @topic_id,
        zoom_id: Webinar.sanitize_zoom_id(@zoom_id),
        title: @attrs[:title],
        starts_at: @attrs[:starts_at],
        ends_at: @attrs[:ends_at],
        duration: @attrs[:duration],
        zoom_host_id: @attrs[:zoom_host_id],
        password: @attrs[:password],
        host_video: @attrs[:host_video],
        panelists_video: @attrs[:panelists_video],
        approval_type: @attrs[:approval_type].to_i,
        enforce_login: @attrs[:enforce_login],
        registrants_restrict_number: @attrs[:registrants_restrict_number],
        meeting_authentication: @attrs[:meeting_authentication],
        on_demand: @attrs[:on_demand],
        join_url: @attrs[:join_url],
      )
      host_data = Zoom::Client.new.host(@attrs[:zoom_host_id])
      user = User.find_by_email(host_data[:email])
      unless user
        user = User.create!(
          email: host_data[:email],
          username: UserNameSuggester.suggest(host_data[:email]),
          name: User.suggest_name(host_data[:email]),
          staged: true
        )
      end
      WebinarUser.find_or_create_by(user: user, webinar: webinar, type: :host)

      register_panelists(webinar)
      webinar
    end

    private

    def register_panelists(webinar)
      data = @zoom_client.panelists(webinar.zoom_id, true)

      data[:panelists].each do |panelist_attrs|
        user = User.with_email(Email.downcase(panelist_attrs[:email])).first
        if !user
          user = User.create!(
            email: panelist_attrs[:email],
            username: UserNameSuggester.suggest(panelist_attrs[:email]),
            name: User.suggest_name(panelist_attrs[:email]),
            staged: true
          )
        end

        existin_records = WebinarUser.where(webinar: webinar, user: user)
        if existin_records.any?
          existin_records.update_all(type: :panelist)
        else
          WebinarUser.create!(
            webinar: webinar,
            user: user,
            type: :panelist,
          )
        end
      end
    end
  end
end

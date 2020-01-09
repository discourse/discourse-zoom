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
      WebinarUser.find_or_create_by(user: user, webinar: webinar, type: :host, registration_status: :approved)

      register_users(webinar, :attendees)
      register_users(webinar, :panelists)
      webinar
    end

    private

    def register_users(webinar, type)
      data = @zoom_client.send(type, webinar.zoom_id, true)

      key = type == :attendees ? :registrants : :panelists
      data[key].each do |panelist_attrs|
        user = User.with_email(Email.downcase(panelist_attrs[:email])).first
        next unless user

        registration_status = WebinarUser.registration_status_translation(panelist_attrs[:status]) || :approved
        registration_type = type.to_s.chomp("s").to_sym

        existin_records = WebinarUser.where(webinar: webinar, user: user)
        if existin_records.any?
          existin_records.update_all(type: registration_type, registration_status: registration_status)
        else
          WebinarUser.create!(
            webinar: webinar,
            user: user,
            type: registration_type,
            registration_status: registration_status
          )
        end
      end
    end
  end
end

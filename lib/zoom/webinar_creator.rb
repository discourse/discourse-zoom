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

      register_attendees(webinar.zoom_id)
      register_speakers(webinar.zoom_id)
      webinar
    end

    private

    def register_attendees(webinar_id)
    end

    def register_speakers(webinar_id)
      speaker_data = @zoom_client.speakers(webinar_id, true)
      speaker_data[:panelists].each do |speaker_attrs|
        user = User.with_email(Email.downcase(speaker_attrs[:email])).first
        if user
          WebinarUser.where(webinar_id: webinar_id, user: user).destroy_all
          WebinarUser.create(webinar_id: webinar_id,
                             user: user,
                             type: :speaker,
                             registration_status: :approved)
        end
      end

    end
  end
end

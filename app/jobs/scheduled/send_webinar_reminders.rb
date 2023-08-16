# frozen_string_literal: true

module Jobs
  class ::Zoom::SendWebinarReminders < ::Jobs::Scheduled
    every 5.minutes

    def execute(args)
      reminder_time = SiteSetting.zoom_send_reminder_minutes_before_webinar&.to_i
      return if reminder_time < 0

      webinars = Webinar.where('starts_at > ? AND starts_at < ? AND reminders_sent_at IS NULL', DateTime.now, DateTime.now + reminder_time.minutes + 2.5.minutes).each do |webinar|
        webinar.webinar_users.each do |webinar_user|
          ::Jobs.enqueue(
            :send_system_message,
            user_id: webinar_user.user_id,
            message_type: 'webinar_reminder',
            message_options: {
              url: webinar.topic.url
            }
          )
        end
        webinar.update(reminders_sent_at: DateTime.now)
      end
    end
  end
end

# frozen_string_literal: true
require_relative "../fabricators/webinar_fabricator.rb"

RSpec.describe Zoom::SendWebinarReminders do
  fab!(:topic_1) { Fabricate(:topic) }
  fab!(:topic_2) { Fabricate(:topic) }
  fab!(:user_1) { Fabricate(:user) }
  fab!(:user_2) { Fabricate(:user) }
  let(:needs_reminding) do
    Fabricate(:webinar, topic: topic_1, starts_at: DateTime.now + 20.minutes)
  end
  let(:no_reminder) { Fabricate(:webinar, topic: topic_2, starts_at: DateTime.now + 2.days) }

  before do
    Jobs.run_immediately!
    needs_reminding.webinar_users.create(user: user_1, type: :attendee)
    needs_reminding.webinar_users.create(user: user_2, type: :attendee)
    no_reminder.webinar_users.create(user: user_1, type: :attendee)
  end
  describe "with zoom_send_reminder_minutes_before_webinar set to 0" do
    before { SiteSetting.zoom_send_reminder_minutes_before_webinar = "" }

    it "does not send reminders" do
      SystemMessage
        .any_instance
        .expects(:create)
        .with() { |value| value == "webinar_reminder" }
        .never
      Zoom::SendWebinarReminders.new.execute({})
    end
  end

  describe "with zoom_send_reminder_minutes_before_webinar set to 0" do
    before { SiteSetting.zoom_send_reminder_minutes_before_webinar = "0" }

    it "does not send reminders" do
      SystemMessage
        .any_instance
        .expects(:create)
        .with() { |value| value == "webinar_reminder" }
        .never
      Zoom::SendWebinarReminders.new.execute({})
    end
  end

  describe "with zoom_send_reminder_minutes_before_webinar set to 30 minutes" do
    before { SiteSetting.zoom_send_reminder_minutes_before_webinar = "30" }
    it "sends reminders for upcoming webinars" do
      expect(needs_reminding.reload.reminders_sent_at).to eq(nil)
      SystemMessage
        .any_instance
        .expects(:create)
        .with() { |value| value == "webinar_reminder" }
        .twice

      Zoom::SendWebinarReminders.new.execute({})
      expect(needs_reminding.reload.reminders_sent_at).not_to eq(nil)
    end

    it "does not re-send to those already reminded" do
      needs_reminding.update(reminders_sent_at: DateTime.now)

      SystemMessage
        .any_instance
        .expects(:create)
        .with() { |value| value == "webinar_reminder" }
        .never
      Zoom::SendWebinarReminders.new.execute({})
    end
  end
end

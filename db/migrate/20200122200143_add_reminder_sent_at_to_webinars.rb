# frozen_string_literal: true
class AddReminderSentAtToWebinars < ActiveRecord::Migration[6.0]
  def change
    add_column :webinars, :reminders_sent_at, :datetime
  end
end

# frozen_string_literal: true
class AddRegistrationStatusToWebinarUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :webinar_users, :registration_status, :integer, default: 0, null: false
  end
end

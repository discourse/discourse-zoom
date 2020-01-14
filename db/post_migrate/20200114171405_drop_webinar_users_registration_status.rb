class DropWebinarUsersRegistrationStatus < ActiveRecord::Migration[6.0]
  def up
    remove_column :webinar_users, :registration_status
  end
end

class DropWebinarUsersRegistrationStatus < ActiveRecord::Migration[6.0]
  def change
    remove_column :webinar_users, :registration_status, :integer
  end
end

# frozen_string_literal: true
class DropWebinarUsersRegistrationStatus < ActiveRecord::Migration[6.0]
  def up
    remove_column :webinar_users, :registration_status
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

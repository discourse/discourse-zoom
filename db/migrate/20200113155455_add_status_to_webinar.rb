class AddStatusToWebinar < ActiveRecord::Migration[6.0]
  def change
    add_column :webinars, :status, :integer, default: 0, null: false
  end
end

class AddWebinarSettings < ActiveRecord::Migration[6.0]
  def change
    change_table :webinars do |t|
      t.boolean :host_video
      t.boolean :panelists_video
      t.integer :approval_type, default: 2, null: false
      t.boolean :enforce_login
      t.integer :registrants_restrict_number, default: 0, null: false
      t.boolean :meeting_authentication
      t.boolean :on_demand
      t.string :join_url
      t.string :password
    end
  end
end

# frozen_string_literal: true
class AddWebinarAttributes < ActiveRecord::Migration[6.0]
  def change
    change_table :webinars do |t|
      t.string :title
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :duration
      t.string :zoom_host_id
      t.timestamps null: false
    end
  end
end

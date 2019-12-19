# frozen_string_literal: true
class CreateWebinars < ActiveRecord::Migration[6.0]
  def change
    create_table :webinars do |t|
      t.integer :topic_id
      t.string :zoom_id
    end
  end
end

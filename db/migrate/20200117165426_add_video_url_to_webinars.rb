# frozen_string_literal: true
class AddVideoUrlToWebinars < ActiveRecord::Migration[6.0]
  def change
    add_column :webinars, :video_url, :text
  end
end

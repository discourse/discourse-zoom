class CreateZoomWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :zoom_webinar_webhook_events do |t|
      t.string :event
      t.text :payload
      t.integer :webinar_id
      t.integer :zoom_timestamp
      t.timestamps
    end
  end
end

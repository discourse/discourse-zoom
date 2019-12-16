class CreateWebinars < ActiveRecord::Migration[6.0]
  def change
    create_table :webinars do |t|
      t.integer :user_id
      t.integer :topic_id
    end
  end
end

class CreateWebinarUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :webinar_users do |t|
      t.integer :user_id
      t.integer :webinar_id
      t.integer :type
    end
  end
end

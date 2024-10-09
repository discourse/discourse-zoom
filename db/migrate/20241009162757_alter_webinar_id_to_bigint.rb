# frozen_string_literal: true

class AlterWebinarIdToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :webinar_users, :webinar_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

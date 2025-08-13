class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE notif_channel AS ENUM ('email','sms','webpush');
      CREATE TYPE notif_status AS ENUM ('queued','sent','failed','cancelled');
    SQL

    create_table :notifications do |t|
      t.bigint :user_id, null: false
      t.enum :channel, enum_type: 'notif_channel', null: false
      t.text :subject
      t.text :body
      t.enum :status, enum_type: 'notif_status', null: false, default: 'queued'
      t.text :error_msg
      t.bigint :related_fee
      t.bigint :related_patent
      t.timestamptz :scheduled_at
      t.timestamptz :sent_at
      t.timestamps
    end

    add_foreign_key :notifications, :users, on_delete: :cascade
    add_foreign_key :notifications, :annual_fees, column: :related_fee, on_delete: :nullify
    add_foreign_key :notifications, :patents, column: :related_patent, on_delete: :nullify
    
    add_index :notifications, [:user_id, :status]
  end

  def down
    drop_table :notifications
    execute <<-SQL
      DROP TYPE IF EXISTS notif_channel;
      DROP TYPE IF EXISTS notif_status;
    SQL
  end
end
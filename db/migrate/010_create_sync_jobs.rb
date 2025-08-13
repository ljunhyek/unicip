class CreateSyncJobs < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE sync_status AS ENUM ('queued','running','success','warning','failed');
    SQL

    create_table :sync_jobs do |t|
      t.text :job_type, null: false
      t.bigint :requester_id
      t.bigint :target_user_id
      t.enum :status, enum_type: 'sync_status', null: false, default: 'queued'
      t.timestamptz :started_at
      t.timestamptz :finished_at
      t.text :message
      t.timestamps
    end

    add_foreign_key :sync_jobs, :admin_users, column: :requester_id, on_delete: :nullify
    add_foreign_key :sync_jobs, :users, column: :target_user_id, on_delete: :cascade
  end

  def down
    drop_table :sync_jobs
    execute <<-SQL
      DROP TYPE IF EXISTS sync_status;
    SQL
  end
end
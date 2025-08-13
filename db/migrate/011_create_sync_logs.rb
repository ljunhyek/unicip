class CreateSyncLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :sync_logs do |t|
      t.bigint :job_id, null: false
      t.text :patent_app_no
      t.text :level, null: false
      t.text :message
      t.timestamps
    end

    add_foreign_key :sync_logs, :sync_jobs, column: :job_id, on_delete: :cascade
    add_index :sync_logs, :job_id
  end
end
class CreatePatentStatusEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :patent_status_events do |t|
      t.bigint :patent_id, null: false
      t.enum :status, enum_type: 'patent_status', null: false
      t.date :event_date
      t.text :message
      t.timestamps
    end

    add_foreign_key :patent_status_events, :patents, on_delete: :cascade
    add_index :patent_status_events, :patent_id
  end
end
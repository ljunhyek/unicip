class CreatePatents < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE patent_status AS ENUM ('filed','published','granted','rejected','withdrawn','expired');
    SQL

    create_table :patents do |t|
      t.string :application_number, limit: 30, null: false
      t.string :registration_number, limit: 30
      t.text :title_ko
      t.text :title_en
      t.text :applicant_name
      t.jsonb :applicants_json
      t.jsonb :inventors_json
      t.date :filing_date
      t.text :priority_number
      t.boolean :priority_claim, default: false
      t.date :pct_due_date
      t.text :pct_application_no
      t.text :family_numbers
      t.enum :current_status, enum_type: 'patent_status'
      t.date :publication_date
      t.date :grant_date
      t.timestamptz :updated_from_api_at
      t.text :raw_payload_xml
      t.timestamps
    end

    add_index :patents, :application_number, unique: true
    add_index :patents, :registration_number
    add_index :patents, :current_status
  end

  def down
    drop_table :patents
    execute <<-SQL
      DROP TYPE IF EXISTS patent_status;
    SQL
  end
end
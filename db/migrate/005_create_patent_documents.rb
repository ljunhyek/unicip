class CreatePatentDocuments < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE doc_type_enum AS ENUM ('opinion','publication_pdf','announcement_pdf','spec','claims','drawing','others');
    SQL

    create_table :patent_documents do |t|
      t.bigint :patent_id, null: false
      t.enum :doc_type, enum_type: 'doc_type_enum', null: false
      t.text :title
      t.text :url
      t.boolean :downloaded, default: false
      t.text :file_key
      t.timestamps
    end

    add_foreign_key :patent_documents, :patents, on_delete: :cascade
    add_index :patent_documents, :patent_id
  end

  def down
    drop_table :patent_documents
    execute <<-SQL
      DROP TYPE IF EXISTS doc_type_enum;
    SQL
  end
end
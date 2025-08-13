class CreateUserPatents < ActiveRecord::Migration[7.0]
  def change
    create_table :user_patents, primary_key: [:user_id, :patent_id] do |t|
      t.bigint :user_id, null: false
      t.bigint :patent_id, null: false
      t.text :role, default: 'owner'
      t.text :note
      t.timestamps
    end

    add_foreign_key :user_patents, :users, on_delete: :cascade
    add_foreign_key :user_patents, :patents, on_delete: :cascade
    
    add_index :user_patents, :user_id
    add_index :user_patents, :patent_id
  end
end
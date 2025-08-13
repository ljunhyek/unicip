class CreateAnnualFees < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE fee_status_enum AS ENUM ('scheduled','due','overdue','paid','waived','exempt');
    SQL

    create_table :annual_fees do |t|
      t.bigint :patent_id, null: false
      t.integer :year_no, null: false
      t.decimal :amount_krw, precision: 16, scale: 2, null: false
      t.decimal :surcharge_krw, precision: 16, scale: 2, default: 0
      t.date :due_date, null: false
      t.date :grace_end_date
      t.enum :status, enum_type: 'fee_status_enum', null: false, default: 'scheduled'
      t.date :paid_date
      t.text :note
      t.timestamps
    end

    add_foreign_key :annual_fees, :patents, on_delete: :cascade
    add_index :annual_fees, :patent_id
    add_index :annual_fees, [:due_date, :status]
    add_index :annual_fees, [:patent_id, :year_no], unique: true
    add_index :annual_fees, :status, where: "status = 'overdue'"
  end

  def down
    drop_table :annual_fees
    execute <<-SQL
      DROP TYPE IF EXISTS fee_status_enum;
    SQL
  end
end
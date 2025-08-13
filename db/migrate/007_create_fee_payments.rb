class CreateFeePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :fee_payments do |t|
      t.bigint :annual_fee_id, null: false
      t.decimal :pay_amount, precision: 16, scale: 2, null: false
      t.string :currency, limit: 8, default: 'KRW'
      t.timestamptz :paid_at, null: false, default: -> { 'NOW()' }
      t.text :provider
      t.text :receipt_no
      t.text :memo
      t.timestamps
    end

    add_foreign_key :fee_payments, :annual_fees, on_delete: :cascade
    add_index :fee_payments, :annual_fee_id
  end
end
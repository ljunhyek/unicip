class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    # Create ENUM types
    execute <<-SQL
      CREATE TYPE user_type_enum AS ENUM ('corp', 'individual', 'corp_inventor');
    SQL

    create_table :users do |t|
      t.text :cuid, unique: true
      t.citext :email, null: false, unique: true
      t.text :password_hash, null: false
      t.text :name, null: false
      t.enum :user_type, enum_type: 'user_type_enum', null: false
      t.text :manager
      t.text :contact
      t.text :inventor
      t.string :customer_number, limit: 20, unique: true
      t.boolean :terms_agreed, null: false, default: false
      t.boolean :privacy_agreed, null: false, default: false
      t.boolean :email_agreed, null: false, default: false
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :customer_number, unique: true
  end

  def down
    drop_table :users
    execute <<-SQL
      DROP TYPE IF EXISTS user_type_enum;
    SQL
  end
end
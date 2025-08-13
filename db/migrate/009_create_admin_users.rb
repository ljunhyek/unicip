class CreateAdminUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_users do |t|
      t.citext :email, null: false, unique: true
      t.text :password_hash, null: false
      t.text :role, null: false, default: 'admin'
      t.timestamps
    end

    add_index :admin_users, :email, unique: true
  end
end
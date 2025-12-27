class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email,           null: false, index: { unique: true }
      t.string :password_digest, null: false

      t.boolean :verified, null: false, default: false

      t.string :provider
      t.string :uid

      # t.references :parent_company, null: true, foreign_key: { to_table: :companies }, type: :uuid
      t.references :parent_user, null: true, foreign_key: { to_table: :users }, type: :uuid
      t.integer :system_role
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :avatar
      t.string :phone_number
      t.string :country_code
      t.string :single_access_token
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :users, :discarded_at
    add_index :users, :username, unique: true
    add_index :users, :uid, unique: true
    add_index :users, :single_access_token, unique: true
  end
end

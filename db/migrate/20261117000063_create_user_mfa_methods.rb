class CreateUserMfaMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :user_mfa_methods, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid

      # --- Factor ---
      t.integer :method, null: false, default: 0
      t.string  :secret
      t.string  :label
      t.datetime :confirmed_at
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :user_mfa_methods, [ :user_id, :method ]
    add_index :user_mfa_methods, [ :user_id, :revoked_at ]
  end
end

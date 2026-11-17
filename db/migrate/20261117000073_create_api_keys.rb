class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :created_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Credential ---
      t.string   :name, null: false
      t.string   :token_digest, null: false
      t.jsonb    :scopes, default: []
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :token_digest, unique: true
    add_index :api_keys, [ :company_id, :revoked_at ]
  end
end

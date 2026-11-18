class CreateIdempotencyKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :idempotency_keys, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Memo ---
      t.string   :key, null: false
      t.string   :request_digest, null: false
      t.jsonb    :response, default: {}
      t.integer  :response_status, null: false, default: 200
      t.datetime :expires_at

      t.timestamps
    end

    add_index :idempotency_keys, [ :company_id, :key ], unique: true
    add_index :idempotency_keys, [ :expires_at ]
  end
end

class CreateSignatureEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_events, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :signature_request, null: false, foreign_key: true, type: :uuid

      # --- Signer ---
      t.string   :signer_email, null: false
      t.string   :signer_name
      t.datetime :signed_at
      t.string   :ip_address
      t.string   :signature_hash
      t.jsonb    :metadata, default: {}

      t.timestamps
    end

    add_index :signature_events, [ :signature_request_id, :signed_at ]
  end
end

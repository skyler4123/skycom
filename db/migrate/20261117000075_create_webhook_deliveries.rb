class CreateWebhookDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_deliveries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :webhook_endpoint, null: false, foreign_key: true, type: :uuid

      # --- Delivery ---
      t.string   :event_key, null: false
      t.jsonb    :payload, default: {}
      t.integer  :status, null: false, default: 0
      t.integer  :attempts, null: false, default: 1
      t.integer  :response_code
      t.datetime :delivered_at
      t.text     :error_message

      t.timestamps
    end

    add_index :webhook_deliveries, [ :webhook_endpoint_id, :created_at ]
    add_index :webhook_deliveries, [ :status, :created_at ]
  end
end

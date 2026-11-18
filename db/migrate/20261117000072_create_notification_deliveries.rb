class CreateNotificationDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_deliveries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :notification, null: false, foreign_key: true, type: :uuid
      t.references :notification_channel, null: false, foreign_key: true, type: :uuid

      # --- Attempt ---
      t.integer  :status, null: false, default: 0
      t.integer  :attempts, null: false, default: 1
      t.datetime :sent_at
      t.integer  :response_code
      t.text     :error_message

      t.timestamps
    end

    add_index :notification_deliveries, [ :notification_id, :notification_channel_id ]
    add_index :notification_deliveries, [ :status, :created_at ]
  end
end

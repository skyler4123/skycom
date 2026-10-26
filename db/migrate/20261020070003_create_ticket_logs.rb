class CreateTicketLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :ticket, null: false, foreign_key: true, type: :uuid

      t.string :actor_type
      t.uuid :actor_id
      t.integer :action, null: false, default: 0
      t.string :from_status
      t.string :to_status
      t.text :note

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :ticket_logs, [ :company_id, :ticket_id ]
  end
end

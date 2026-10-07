class CreateCompanyTicketLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :company_ticket_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :company_ticket, null: false, foreign_key: true, type: :uuid
      t.references :actor, polymorphic: true, null: true, type: :uuid

      t.integer :action, null: false
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

    add_index :company_ticket_logs, [ :company_ticket_id, :created_at ]
  end
end

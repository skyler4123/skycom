class CreateInvoiceReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_reminders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :invoice, null: false, foreign_key: true, type: :uuid

      # --- Dunning ---
      t.integer  :level, null: false, default: 1
      t.integer  :channel, null: false, default: 0
      t.date     :scheduled_on
      t.datetime :sent_at
      t.integer  :status, null: false, default: 0
      t.text     :notes

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :invoice_reminders, [ :company_id, :scheduled_on ]
    add_index :invoice_reminders, [ :invoice_id, :level ]
  end
end

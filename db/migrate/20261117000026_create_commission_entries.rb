class CreateCommissionEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_entries, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :commission_plan, null: false, foreign_key: true, type: :uuid
      t.references :order, foreign_key: true, type: :uuid
      t.references :invoice, foreign_key: true, type: :uuid
      t.references :payroll, foreign_key: true, type: :uuid

      # --- Amount ---
      t.bigint  :base_cents, null: false, default: 0
      t.bigint  :amount_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.integer :status, null: false, default: 0
      t.text    :notes

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

    add_index :commission_entries, [ :company_id, :employee_id, :status ]
  end
end

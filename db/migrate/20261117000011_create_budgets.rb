class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :cost_center, foreign_key: true, type: :uuid
      t.references :fiscal_period, foreign_key: true, type: :uuid
      t.references :workflow_step, foreign_key: true, type: :uuid

      # --- Budget ---
      t.string  :name, null: false
      t.text    :description
      t.integer :budget_scope, null: false, default: 0
      t.bigint  :amount_cents, null: false, default: 0
      t.integer :currency, default: 840

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

    add_index :budgets, [ :company_id, :name ], unique: true
    add_index :budgets, [ :company_id, :budget_scope ]
  end
end

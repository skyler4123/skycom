class CreateBudgetLines < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_lines, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :budget, null: false, foreign_key: true, type: :uuid
      t.references :ledger_account, null: false, foreign_key: true, type: :uuid

      # --- Amount ---
      t.date    :period_month, null: false
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

    add_index :budget_lines, [ :budget_id, :ledger_account_id, :period_month ], unique: true, name: "idx_budget_lines_unique"
  end
end

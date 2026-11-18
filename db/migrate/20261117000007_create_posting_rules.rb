class CreatePostingRules < ActiveRecord::Migration[8.0]
  def change
    create_table :posting_rules, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :debit_ledger_account,  null: false, foreign_key: { to_table: :ledger_accounts }, type: :uuid
      t.references :credit_ledger_account, null: false, foreign_key: { to_table: :ledger_accounts }, type: :uuid

      # --- Rule ---
      t.string  :event_key, null: false
      t.string  :name
      t.integer :priority, null: false, default: 0
      t.jsonb   :conditions, default: {}
      t.boolean :is_active, null: false, default: true

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

    add_index :posting_rules, [ :company_id, :event_key, :priority ], unique: true
  end
end

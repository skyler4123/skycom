class CreateLedgerAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_accounts, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :ledger_accounts }, type: :uuid

      # --- Identity ---
      t.string  :code, null: false
      t.string  :name, null: false
      t.text    :description
      t.integer :account_type,   null: false
      t.integer :normal_balance, null: false
      t.boolean :is_control,      null: false, default: false
      t.boolean :is_reconcilable, null: false, default: false
      t.boolean :is_active,       null: false, default: true
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

    add_index :ledger_accounts, [ :company_id, :code ], unique: true
    add_index :ledger_accounts, [ :company_id, :parent_id ]
  end
end

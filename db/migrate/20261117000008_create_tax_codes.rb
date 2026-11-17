class CreateTaxCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_codes, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :ledger_account, foreign_key: true, type: :uuid

      # --- Code ---
      t.string  :code, null: false
      t.string  :name, null: false
      t.text    :description
      t.integer :kind, null: false
      t.integer :rate_bp, null: false, default: 0
      t.string  :jurisdiction
      t.boolean :is_inclusive, null: false, default: false
      t.date    :effective_from
      t.date    :effective_to

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

    add_index :tax_codes, [ :company_id, :code ], unique: true
  end
end

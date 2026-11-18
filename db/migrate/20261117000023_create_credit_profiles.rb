class CreateCreditProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_profiles, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :reviewed_by_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Credit ---
      t.bigint  :limit_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.boolean :hold_orders, null: false, default: false
      t.datetime :reviewed_at
      t.text :notes

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

    add_index :credit_profiles, [ :company_id, :customer_id ], unique: true
  end
end

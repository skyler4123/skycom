class CreateFixedAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :fixed_assets, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :ledger_account, foreign_key: true, type: :uuid
      t.references :cost_center, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :code, null: false
      t.string :name, null: false
      t.text   :description

      # --- Acquisition ---
      t.date    :acquired_on, null: false
      t.bigint  :cost_cents, null: false, default: 0
      t.bigint  :salvage_cents, null: false, default: 0
      t.integer :currency, default: 840

      # --- Depreciation ---
      t.integer :useful_life_months, null: false
      t.integer :depreciation_method, null: false, default: 0

      # --- Disposal ---
      t.date :disposed_on

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

    add_index :fixed_assets, [ :company_id, :code ], unique: true
    add_index :fixed_assets, [ :company_id, :disposed_on ]
  end
end

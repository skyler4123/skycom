class CreateCommissionTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_tiers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :commission_plan, null: false, foreign_key: true, type: :uuid

      # --- Bracket ---
      t.bigint  :from_cents, null: false, default: 0
      t.bigint  :to_cents
      t.integer :rate_bp, null: false, default: 0

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

    add_index :commission_tiers, [ :commission_plan_id, :from_cents ], unique: true
  end
end

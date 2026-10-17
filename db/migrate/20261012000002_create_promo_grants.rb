class CreatePromoGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :promo_grants, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :promo_campaign, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.bigint :granted_amount, null: false
      t.bigint :promo_before, null: false
      t.bigint :promo_after, null: false

      t.string :external_id, index: true

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :promo_grants, [ :promo_campaign_id, :company_id ], unique: true
  end
end

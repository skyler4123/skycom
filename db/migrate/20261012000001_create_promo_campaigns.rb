class CreatePromoCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :promo_campaigns, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string :name, null: false
      t.text :description
      t.bigint :amount, null: false
      t.bigint :max_cap, null: false
      t.jsonb :conditions, default: {}, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.datetime :processed_at
      t.jsonb :stats, default: {}, null: false

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

    add_index :promo_campaigns, :status
    add_index :promo_campaigns, :scheduled_at
  end
end

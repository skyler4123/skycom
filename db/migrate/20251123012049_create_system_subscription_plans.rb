class CreateSystemSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :system_subscription_plans, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.string :code
      t.integer :duration_days
      t.integer :country_code
      t.jsonb :features, default: {}
      t.jsonb :limits, default: {}

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
  end
end

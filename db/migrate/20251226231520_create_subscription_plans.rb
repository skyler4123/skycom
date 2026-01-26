class CreateSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :description
      t.string :code
      t.integer :duration_days
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.integer :country_code
      t.jsonb :features, default: {}
      t.jsonb :limits, default: {}
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :subscription_plans, :discarded_at
  end
end

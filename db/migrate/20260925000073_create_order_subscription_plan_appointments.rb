class CreateOrderSubscriptionPlanAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_subscription_plan_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :order, null: false, foreign_key: { to_table: :orders }, type: :uuid
      t.references :subscription_plan, null: false, foreign_key: { to_table: :subscription_plans }, type: :uuid
      t.references :stock, null: true, foreign_key: true, type: :uuid
      t.decimal :unit_price
      t.integer :quantity
      t.decimal :total_price
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :order_subscription_plan_appointments, [ :company_id, :order_id, :subscription_plan_id ], name: "idx_order_subscription_plan_appointments_triple"
  end
end

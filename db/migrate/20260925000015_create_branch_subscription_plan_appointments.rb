class CreateBranchSubscriptionPlanAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :branch_subscription_plan_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: { to_table: :branches }, type: :uuid
      t.references :subscription_plan, null: false, foreign_key: { to_table: :subscription_plans }, type: :uuid
      t.integer :price_cents
      t.integer :currency
      t.integer :country
      t.integer :timezone
      t.boolean :auto_renew
      t.string :name
      t.string :description
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :branch_subscription_plan_appointments, [:company_id, :branch_id, :subscription_plan_id], name: "idx_branch_subscription_plan_appointments_triple"
  end
end

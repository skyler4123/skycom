class CreateSubscriptionGroupSubscriptionPlanAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_group_subscription_plan_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :subscription_group, null: false, foreign_key: { to_table: :subscription_groups }, type: :uuid
      t.references :subscription_plan, null: false, foreign_key: { to_table: :subscription_plans }, type: :uuid
      t.integer :price_cents
      t.integer :currency
      t.integer :country
      t.integer :timezone
      t.boolean :auto_renew
      t.string :name
      t.string :description
      # Postgres truncates identifiers over 63 chars; the default index name for this
      # table is 70 chars, so pin an explicit shorter one.
      t.string :external_id, index: { name: "index_subscription_group_sub_plan_appts_on_external_id" }
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :subscription_group_subscription_plan_appointments, [ :company_id, :subscription_group_id, :subscription_plan_id ], name: "idx_subscription_group_subscription_plan_appointments_triple"
  end
end

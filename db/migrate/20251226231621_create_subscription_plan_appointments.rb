class CreateSubscriptionPlanAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plan_appointments, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :subscription_plan, null: true, foreign_key: true, type: :uuid
      t.references :subscription_group, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.integer :country_code, null: false
      t.integer :timezone

      # --- State Columns (Moved Here) ---
      t.integer :lifecycle_status  # e.g., active, expired, canceled
      t.integer :workflow_status   # e.g., pending_payment, active
      t.integer :business_type     # e.g., b2b, b2c (context specific)
      t.boolean :auto_renew        # Instance specific setting
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :subscription_plan_appointments, :discarded_at
  end
end

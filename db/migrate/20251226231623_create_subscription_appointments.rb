class CreateSubscriptionAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_appointments, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid

      # The entity selling the subscription (e.g., System, Company)
      t.references :appoint_from, polymorphic: true, null: false, type: :uuid

      # The entity owning/using the subscription (e.g., User, Company Group, Company, Customer)
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid

      # The specific resource the subscription applies to (if applicable)
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid

      # Who processed the subscription (e.g., Admin/System)
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code

      # --- State Columns (Moved Here) ---
      t.integer :lifecycle_status  # e.g., active, expired, canceled
      t.integer :workflow_status   # e.g., pending_payment, active
      t.integer :business_type     # e.g., b2b, b2c (context specific)
      t.boolean :auto_renew        # Instance specific setting

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :subscription_appointments, :discarded_at
    add_index :subscription_appointments, [ :appoint_to_type, :appoint_to_id ]

    # Helpful index for finding active subscriptions quickly
    add_index :subscription_appointments, :lifecycle_status
  end
end

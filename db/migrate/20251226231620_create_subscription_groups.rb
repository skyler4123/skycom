class CreateSubscriptionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_groups, id: :uuid do |t|
      t.references :subscription_group, null: true, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid

      # The entity selling the subscription (e.g., System, Company)
      t.references :seller, polymorphic: true, null: false, type: :uuid

      # The entity owning/using the subscription (e.g., User, Company Group, Company, Customer)
      t.references :buyer, polymorphic: true, null: false, type: :uuid

      # Who processed the subscription (e.g., Admin/System)
      t.references :processed_by, polymorphic: true, null: true, type: :uuid

      t.string :name
      t.string :description
      t.integer :plan_name
      t.integer :country_code

      # --- State Columns (Moved Here) ---
      t.integer :lifecycle_status  # e.g., active, expired, canceled
      t.integer :workflow_status   # e.g., pending_payment, active
      t.integer :business_type     # e.g., b2b, b2c (context specific)
      t.boolean :auto_renew        # Instance specific setting
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :subscription_groups, :discarded_at
  end
end

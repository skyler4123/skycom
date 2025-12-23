# db/migrate/2024XXXXXX_create_subscriptions.rb
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      # 1. References to your shared models
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid

      # 2. The Plan (Integer Enum)
      # default: 0 (e.g., Free or Basic)
      t.integer :plan_name, default: 0, null: false

      # 3. Two-Dimensional Status (Integer Enums)
      
      # Lifecycle: Is this record technically alive in the system?
      # default: 0 (Draft/Initialized)
      t.integer :lifecycle_status, default: 0, null: false
      
      # Workflow: Where is the user in the payment journey?
      # default: 0 (Pending Action)
      t.integer :workflow_status, default: 0, null: false

      # 4. Region
      t.string :country_code

      # 5. Settings
      t.boolean :auto_renew, default: true, null: false

      t.timestamps
    end

    # Indexes for high-performance queries
    # e.g. "Find all Live subscriptions that are Past Due"
    add_index :subscriptions, [:lifecycle_status, :workflow_status]
    add_index :subscriptions, [:user_id, :lifecycle_status]
  end
end

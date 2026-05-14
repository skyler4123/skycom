class CreateSystemSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :system_subscriptions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :system_subscription_plan, null: false, foreign_key: true, type: :uuid
      t.references :system_subscription_group, null: true, foreign_key: true, type: :uuid
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :country_code, null: false
      t.boolean :auto_renew

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

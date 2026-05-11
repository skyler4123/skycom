class CreateSubscriptionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_groups, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :subscription_plan, null: true, foreign_key: true, type: :uuid
      t.references :subscription_group, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.integer :country_code, null: false
      t.integer :timezone
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

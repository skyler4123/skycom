class CreateSystemSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :system_subscriptions, id: :uuid do |t|
      t.references :system_subscription_plan, null: false, foreign_key: true, type: :uuid
      t.references :system_subscription_group, null: true, foreign_key: true, type: :uuid
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      # The entity selling the subscription (e.g., System, Company)
      t.references :seller, polymorphic: true, null: false, type: :uuid

      # The entity owning/using the subscription (e.g., User, Company Group, Company, Customer)
      t.references :buyer, polymorphic: true, null: false, type: :uuid

      # The specific resource the subscription applies to (if applicable)
      t.references :resource, polymorphic: true, null: true, type: :uuid

      # Who processed the subscription (e.g., Admin/System)
      t.references :processer, polymorphic: true, null: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.integer :country_code
      t.boolean :auto_renew
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :system_subscriptions, :discarded_at
  end
end

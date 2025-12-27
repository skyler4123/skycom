class CreateSubscriptionGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_groups, id: :uuid do |t|
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.string :country_code
      t.boolean :auto_renew
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :subscription_groups, :discarded_at
  end
end

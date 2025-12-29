class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :subscription_group, null: true, foreign_key: true, type: :uuid
      t.references :price, null: false, foreign_key: true, type: :uuid
      t.references :period, null: false, foreign_key: true, type: :uuid
      
      t.string :name
      t.string :description
      t.string :code
      t.string :country_code
      
      # Removed state columns (lifecycle_status, workflow_status, business_type, auto_renew)
      # to keep this model stateless.

      t.datetime :discarded_at
      t.timestamps
    end
    add_index :subscriptions, :discarded_at
  end
end

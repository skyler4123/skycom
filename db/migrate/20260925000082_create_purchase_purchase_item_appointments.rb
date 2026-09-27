class CreatePurchasePurchaseItemAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_purchase_item_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :purchase, null: false, foreign_key: { to_table: :purchases }, type: :uuid
      t.references :purchase_item, null: false, foreign_key: { to_table: :purchase_items }, type: :uuid
      t.integer :quantity
      t.decimal :unit_price
      t.decimal :total_price
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name
      t.timestamps
    end
    add_index :purchase_purchase_item_appointments, [:company_id, :purchase_id, :purchase_item_id], name: "idx_purchase_purchase_item_appointments_triple"
  end
end

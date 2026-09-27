class CreatePurchaseItemTagAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_item_tag_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :purchase_item, null: false, foreign_key: { to_table: :purchase_items }, type: :uuid
      t.references :tag, null: false, foreign_key: { to_table: :tags }, type: :uuid
      t.string :value
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
    add_index :purchase_item_tag_appointments, [:company_id, :purchase_item_id, :tag_id], unique: true, name: "idx_purchase_item_tag_appointments_uniq"
  end
end

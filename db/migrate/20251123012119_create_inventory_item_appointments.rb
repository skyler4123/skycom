class CreateInventoryItemAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_item_appointments, id: :uuid do |t|
      t.references :inventory_item, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: false, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: false, type: :uuid
      t.references :appoint_by, polymorphic: true, null: false, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :inventory_item_appointments, :discarded_at
  end
end

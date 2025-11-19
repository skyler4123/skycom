class CreateOrderItemAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_item_appointments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.decimal :unit_price
      t.integer :quantity
      t.decimal :total_price
      t.string :name
      t.string :description
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :order_item_appointments, :discarded_at
  end
end

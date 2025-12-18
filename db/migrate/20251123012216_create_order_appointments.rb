class CreateOrderAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_appointments, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: false, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid
      t.decimal :unit_price
      t.integer :quantity
      t.decimal :total_price
      t.string :name
      t.string :description
      t.string :code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :order_appointments, :discarded_at
  end
end

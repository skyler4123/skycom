class CreateCartAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_appointments do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :appoint_from, polymorphic: true, null: false
      t.references :appoint_to, polymorphic: true, null: false
      t.references :appoint_for, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :cart_appointments, :discarded_at
  end
end

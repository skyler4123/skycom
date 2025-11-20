class CreateCustomerGroupAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_group_appointments do |t|
      t.references :customer_group, null: false, foreign_key: true
      t.references :appoint_to, polymorphic: true, null: false
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :customer_group_appointments, :discarded_at
  end
end

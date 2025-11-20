class CreatePaymentMethodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_method_appointments do |t|
      t.references :payment_method, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :payment_method_appointments, :discarded_at
  end
end

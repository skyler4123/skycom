class CreatePaymentMethodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_method_appointments, id: :uuid do |t|
      t.references :payment_method, null: false, foreign_key: true, type: :uuid
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid

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

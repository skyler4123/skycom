class CreateBranchPaymentMethodAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :branch_payment_method_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: { to_table: :branches }, type: :uuid
      t.references :payment_method, null: false, foreign_key: { to_table: :payment_methods }, type: :uuid
      t.string :merchant_number
      t.string :merchant_name
      t.string :merchant_id
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
    add_index :branch_payment_method_appointments, [ :company_id, :branch_id, :payment_method_id ], unique: true, name: "idx_branch_payment_method_appointments_uniq"
  end
end

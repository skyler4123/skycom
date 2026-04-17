class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :currency_code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
      t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :payment_methods, :discarded_at
  end
end

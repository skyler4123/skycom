class CreateRefunds < ActiveRecord::Migration[8.0]
  def change
    create_table :refunds, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :customer, null: true, foreign_key: true, type: :uuid
      t.references :order, null: true, foreign_key: true, type: :uuid
      t.references :invoice, null: true, foreign_key: true, type: :uuid
      t.references :transaction, null: true, foreign_key: true, type: :uuid
      t.references :payment_method, null: true, foreign_key: true, type: :uuid
      t.references :product, null: true, foreign_key: true, type: :uuid
      t.references :workflow_step, null: true, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :name
      t.text :description
      t.string :code, index: { unique: true }
      t.integer :refund_type, null: false, default: 0
      t.text :reason
      t.integer :money_amount_cents
      t.integer :currency
      t.integer :quantity
      t.integer :country
      t.integer :timezone

      t.string :external_id, index: true

      # --- System Fields ---
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(5) { |i| t.string "property_string_#{i}" }
      1.upto(10) { |i| t.integer "property_integer_#{i}" }
      1.upto(5) { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(5) { |i| t.boolean "property_boolean_#{i}" }
      1.upto(5) { |i| t.datetime "property_datetime_#{i}" }

      t.timestamps
    end
    add_index :refunds, :refund_type
  end
end

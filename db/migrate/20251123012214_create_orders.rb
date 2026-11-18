class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: true, type: :uuid,
                   foreign_key: { to_table: :employees, on_delete: :nullify }
      t.references :payment_term, null: true, type: :uuid
      t.references :price_list, null: true, type: :uuid
      t.references :channel_connection, null: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency
      t.integer :country
      t.integer :timezone

      t.string :external_id, index: true

      # --- Commercial Document ---
      t.integer :document_type, null: false, default: 1
      t.bigint :total_cents, null: false, default: 0
      t.bigint :tax_cents, null: false, default: 0
      t.decimal :currency_rate, precision: 18, scale: 10, default: "1.0"
      t.datetime :converted_at
      t.string :external_order_number

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(5) { |i| t.string "property_string_#{i}" }
      # 1.upto(5) { |i| t.text "property_text_#{i}" }
      1.upto(10) { |i| t.integer "property_integer_#{i}" }
      1.upto(5)  { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(5)  { |i| t.boolean "property_boolean_#{i}" }
      1.upto(5)  { |i| t.datetime "property_datetime_#{i}" }

      t.timestamps
    end

    add_index :orders, [ :company_id, :document_type ]
    add_index :orders, [ :company_id, :employee_id, :created_at ],
              name: "index_orders_on_company_employee_created_at"
  end
end

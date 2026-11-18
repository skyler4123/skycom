class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :supplier, null: true, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :workflow_step, null: true, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid
      t.references :payment_term, null: true, type: :uuid

      # --- Identity ---
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.datetime :needed_by
      t.integer :currency
      t.integer :country
      t.integer :timezone

      t.string :external_id, index: true

      # --- Commercial Document ---
      t.integer :document_type, null: false, default: 2
      t.bigint :total_cents, null: false, default: 0
      t.decimal :currency_rate, precision: 18, scale: 10, default: "1.0"
      t.datetime :converted_at
      t.datetime :approved_at
      t.datetime :received_at
      t.datetime :billed_at

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

    add_index :purchases, [ :company_id, :document_type ]
    add_foreign_key :stock_imports, :purchases, column: :purchase_id
  end
end

class CreateStockTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_transfers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      t.references :appoint_from, polymorphic: true, null: true, type: :uuid
      t.references :appoint_to, polymorphic: true, null: true, type: :uuid
      t.references :appoint_for, polymorphic: true, null: true, type: :uuid
      t.references :appoint_by, polymorphic: true, null: true, type: :uuid

      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency_code, default: 840 # USD
      t.integer :country_code,  default: 1   # US
      t.string  :timezone,      default: "UTC" # Global Standard

      t.integer :quantity

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(10) { |i| t.string "property_string_#{i}" }
      1.upto(5) { |i| t.text "property_text_#{i}" }
      1.upto(20) { |i| t.integer "property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "property_boolean_#{i}" }
      1.upto(10)  { |i| t.datetime "property_datetime_#{i}" }

      t.timestamps
    end
  end
end

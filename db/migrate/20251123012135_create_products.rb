class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do |t|
      # --- Base Identity ---
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch,  null: true,  foreign_key: true, type: :uuid
      t.references :brand,   null: true,  foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.text   :description
      t.string :code, index: true
      t.string :sku,  index: true
      t.string :barcode

      # --- 1. Physical Properties (The "Thing" Attributes) ---
      t.string :material     # e.g., "Organic Cotton", "Stainless Steel", "Plastic"
      t.string :color        # e.g., "Midnight Black", "Hasaki Green"
      t.string :size         # e.g., "XL", "42", "500ml"
      t.string :shape        # e.g., "Cylindrical", "Rectangular"
      t.string :pattern      # e.g., "Striped", "Matte", "Glossy"
      t.string :flavor_scent # e.g., "Lavender" (Hasaki), "Chocolate" (Gym Supplements)

      # --- 2. Dimensions & Logistics (For Warehousing) ---
      t.decimal :weight,    precision: 10, scale: 3 # kg
      t.decimal :length,    precision: 10, scale: 2 # cm
      t.decimal :width,     precision: 10, scale: 2 # cm
      t.decimal :height,    precision: 10, scale: 2 # cm
      t.decimal :volume,    precision: 10, scale: 3 # Liters/m3
      t.string  :unit_type, default: 'piece'        # e.g., 'pair', 'set', 'pack'

      # --- 3. Manufacturing & Origin ---
      t.string :origin_country # e.g., "VN", "JP", "US"
      t.string :manufacturer_name
      t.string :model_year
      t.string :warranty_info

      # --- 4. Industry Specifics (Gym/Education/Clinic) ---
      t.integer :duration_value
      t.string  :duration_unit
      t.integer :capacity
      t.boolean :is_recurring,  default: false
      t.references :required_role, null: true, foreign_key: { to_table: :roles }, type: :uuid

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true   # retail, education, gym, etc.
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(20) { |i| t.string "dynamic_property_string_#{i}" }
      1.upto(20) { |i| t.integer "dynamic_property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "dynamic_property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "dynamic_property_boolean_#{i}" }
      1.upto(10)  { |i| t.boolean "dynamic_property_datetime_#{i}" }

      t.timestamps
    end
  end
end

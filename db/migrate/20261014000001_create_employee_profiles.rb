class CreateEmployeeProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_profiles, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency
      t.integer :country
      t.integer :timezone

      t.string :external_id, index: true

      # --- System Fields ---
      t.integer :lifecycle_status, index: true
      t.integer :workflow_status, index: true
      t.integer :business_type, index: true
      t.datetime :expiration_date
      t.jsonb :metadata
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(5) { |i| t.string "property_string_#{i}" }
      # 1.upto(5) { |i| t.text "property_text_#{i}" }
      1.upto(10) { |i| t.integer "property_integer_#{i}" }
      1.upto(5)  { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(5)  { |i| t.boolean "property_boolean_#{i}" }
      1.upto(5)  { |i| t.datetime "property_datetime_#{i}" }

      t.timestamps
    end

    add_index :employee_profiles, [ :company_id, :employee_id ]
    add_index :employee_profiles, [ :employee_id, :name ], unique: true, name: "idx_employee_profiles_on_employee_and_name"
  end
end

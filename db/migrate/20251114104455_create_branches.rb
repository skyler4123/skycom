class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    create_table :branches, id: :uuid, default: -> { "uuidv7()" } do |t|
      # --- Hierarchy & Global Scoping ---
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.references :parent_branch, null: true, foreign_key: { to_table: :branches }, type: :uuid

      # --- Identity & Branding ---
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :slug, index: { unique: true }
      t.string :legal_name
      t.string :registration_number
      t.string :vat_id
      t.string :tax_id

      # --- Communication Infrastructure ---
      t.string :email
      t.string :phone_number
      t.string :emergency_phone
      t.string :website
      t.string :social_media_links, array: true, default: []

      # --- Operational Constraints & Capacity ---
      t.integer :ownership_type
      t.integer :currency_code, default: 840 # USD
      t.integer :country_code,  default: 1   # US
      t.string  :timezone,      default: "UTC" # Global Standard
      t.integer :employee_count
      t.integer :fiscal_year_end_month, default: 12
      t.integer :capacity_limit   # Crucial for Hotel/Gym/Hospital scheduling
      t.jsonb   :opening_hours,   default: {}

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name, default: "Branch"

      # --- Dynamic Fields ---
      1.upto(20) { |i| t.string "property_string_#{i}" }
      1.upto(5) { |i| t.text "property_text_#{i}" }
      1.upto(20) { |i| t.integer "property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "property_boolean_#{i}" }
      1.upto(10)  { |i| t.datetime "property_datetime_#{i}" }

      t.timestamps
    end
  end
end

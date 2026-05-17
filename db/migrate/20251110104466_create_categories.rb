class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :resource_name

      # --- Dynamic Fields ---
      1.upto(20) { |i| t.string "property_string_#{i}" }
      1.upto(5) { |i| t.string "property_text_#{i}" }
      1.upto(20) { |i| t.string "property_integer_#{i}" }
      1.upto(10)  { |i| t.string "property_decimal_#{i}" }
      1.upto(10)  { |i| t.string "property_boolean_#{i}" }
      1.upto(10)  { |i| t.string "property_datetime_#{i}" }

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
    add_index :categories, [ :company_id, :name ]
  end
end

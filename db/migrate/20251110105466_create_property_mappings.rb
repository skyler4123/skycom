class CreatePropertyMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :property_mappings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :resource_name

      # --- Dynamic Fields ---
      1.upto(10) { |i| t.jsonb "property_string_#{i}", default: {} }
      1.upto(5) { |i| t.jsonb "property_text_#{i}", default: {} }
      1.upto(20) { |i| t.jsonb "property_integer_#{i}", default: {} }
      1.upto(10)  { |i| t.jsonb "property_decimal_#{i}", default: {} }
      1.upto(10)  { |i| t.jsonb "property_boolean_#{i}", default: {} }
      1.upto(10)  { |i| t.jsonb "property_datetime_#{i}", default: {} }

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
    add_index :property_mappings, [ :company_id, :category_id ]
  end
end

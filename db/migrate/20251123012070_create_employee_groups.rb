class CreateEmployeeGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_groups, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :email
      t.string :name
      t.string :description
      t.string :code

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      # --- Dynamic Fields ---
      1.upto(20) { |i| t.string "dynamic_property_string_#{i}" }
      1.upto(20) { |i| t.integer "dynamic_property_integer_#{i}" }
      1.upto(10)  { |i| t.decimal "dynamic_property_decimal_#{i}", precision: 15, scale: 4 }
      1.upto(10)  { |i| t.boolean "dynamic_property_boolean_#{i}" }
      1.upto(10)  { |i| t.boolean "dynamic_property_datetime_#{i}" }

      t.timestamps
    end
    add_index :employee_groups, [ :company_id, :updated_at ]
  end
end

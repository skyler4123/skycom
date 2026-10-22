class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :assigned_employee, null: true, foreign_key: { to_table: :employees }, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :property_mapping, null: true, foreign_key: true, type: :uuid
      t.references :workflow_step, null: true, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.text :description
      t.integer :priority, null: false, default: 1

      t.string :external_id, index: true

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

    add_index :tickets, [ :company_id, :workflow_status ]
    add_index :tickets, [ :company_id, :assigned_employee_id ]
    add_index :tickets, [ :company_id, :updated_at ]
  end
end
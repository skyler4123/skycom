class CreateCostCenters < ActiveRecord::Migration[8.0]
  def change
    create_table :cost_centers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :cost_centers }, type: :uuid
      t.references :branch, foreign_key: true, type: :uuid
      t.references :manager_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Identity ---
      t.string  :code, null: false
      t.string  :name, null: false
      t.text    :description
      t.boolean :is_active, null: false, default: true

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :cost_centers, [ :company_id, :code ], unique: true
    add_index :cost_centers, [ :company_id, :parent_id ]

    add_foreign_key :employees, :cost_centers, column: :cost_center_id
    add_foreign_key :payrolls, :cost_centers, column: :cost_center_id
    add_foreign_key :projects, :cost_centers, column: :cost_center_id
  end
end

class CreateCommissionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_plans, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :applies_to_category, foreign_key: { to_table: :categories }, type: :uuid
      t.references :applies_to_employee_group, foreign_key: { to_table: :employee_groups }, type: :uuid

      # --- Plan ---
      t.string  :name, null: false
      t.text    :description
      t.integer :basis, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.date    :effective_from
      t.date    :effective_to

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

    add_index :commission_plans, [ :company_id, :name ], unique: true
  end
end

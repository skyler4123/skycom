class CreateCompanyCompanyAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :company_company_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :parent_company, null: false, foreign_key: { to_table: :companies }, type: :uuid
      t.references :child_company,  null: false, foreign_key: { to_table: :companies }, type: :uuid

      # --- Ownership ---
      t.integer :ownership_bp, null: false, default: 10_000
      t.boolean :is_consolidated, null: false, default: true

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

    add_index :company_company_appointments, [ :parent_company_id, :child_company_id ], unique: true, name: "idx_company_company_unique"
  end
end

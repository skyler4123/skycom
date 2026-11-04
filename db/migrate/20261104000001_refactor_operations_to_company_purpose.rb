# frozen_string_literal: true

# Replaces the branch/industry/role-keyed Operation definition with a company-level
# purpose catalog. Branch and warehouse connections become atomic appointment
# rows so the same operation screen can be deployed to any location.
class RefactorOperationsToCompanyPurpose < ActiveRecord::Migration[8.1]
  def up
    # Destructive by design: this catalog is recreated by Seed::OperationService.
    execute "DELETE FROM operations"

    remove_foreign_key :operations, :branches
    remove_index :operations, name: "idx_operations_branch_role_resolution_code"
    remove_index :operations, :branch_id
    remove_index :operations, :business_type
    remove_index :operations, :target_role
    remove_index :operations, :target_resolution

    remove_column :operations, :branch_id
    remove_column :operations, :business_type
    remove_column :operations, :target_role
    remove_column :operations, :target_resolution

    add_column :operations, :operation_type, :integer, null: false
    add_column :operations, :resolution, :integer, null: false
    add_index :operations, [ :company_id, :operation_type, :resolution ], unique: true, name: "index_operations_on_company_type_resolution"

    create_table :branch_operation_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid
      t.references :operation, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :external_id

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :branch_operation_appointments, [ :company_id, :branch_id, :operation_id ], unique: true,
      name: "idx_branch_operation_appointments_uniq"

    create_table :operation_warehouse_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :operation, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.string :external_id

      # --- System Fields ---
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :expiration_date
      t.jsonb :metadata, default: {}, null: false
      t.datetime :discarded_at, index: true
      t.string :permission_resource_name

      t.timestamps
    end

    add_index :operation_warehouse_appointments, [ :company_id, :operation_id, :warehouse_id ], unique: true,
      name: "idx_operation_warehouse_appointments_uniq"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Operations were intentionally destroyed when moving to the purpose catalog."
  end
end

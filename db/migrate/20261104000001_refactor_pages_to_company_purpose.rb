# frozen_string_literal: true

# Replaces the branch/industry/role-keyed Page definition with a company-level
# purpose catalog. Branch and warehouse connections become atomic appointment
# rows so the same operation page can be deployed to any location.
class RefactorPagesToCompanyPurpose < ActiveRecord::Migration[8.1]
  def up
    # Destructive by design: this catalog is recreated by Seed::PageService.
    execute "DELETE FROM pages"

    remove_foreign_key :pages, :branches
    remove_index :pages, name: "idx_on_branch_id_target_role_target_resolution_code_6c16dc00fe"
    remove_index :pages, :branch_id
    remove_index :pages, :business_type
    remove_index :pages, :target_role
    remove_index :pages, :target_resolution

    remove_column :pages, :branch_id
    remove_column :pages, :business_type
    remove_column :pages, :target_role
    remove_column :pages, :target_resolution

    add_column :pages, :page_type, :integer, null: false
    add_column :pages, :resolution, :integer, null: false
    add_index :pages, [ :company_id, :page_type, :resolution ], unique: true

    create_table :branch_page_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid
      t.references :page, null: false, foreign_key: true, type: :uuid

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

    add_index :branch_page_appointments, [ :company_id, :branch_id, :page_id ], unique: true,
      name: "idx_branch_page_appointments_uniq"

    create_table :page_warehouse_appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :page, null: false, foreign_key: true, type: :uuid
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

    add_index :page_warehouse_appointments, [ :company_id, :page_id, :warehouse_id ], unique: true,
      name: "idx_page_warehouse_appointments_uniq"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Pages were intentionally destroyed when moving to the purpose catalog."
  end
end

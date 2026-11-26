# frozen_string_literal: true

class DropCompanyMigrationTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :company_migration_logs, if_exists: true
    drop_table :company_migrations, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

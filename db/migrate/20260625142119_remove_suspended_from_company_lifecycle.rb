# frozen_string_literal: true

class RemoveSuspendedFromCompanyLifecycle < ActiveRecord::Migration[8.0]
  def up
    Company.where(lifecycle_status: 20).update_all(lifecycle_status: 10)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

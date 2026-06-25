# frozen_string_literal: true

class RemapCompanyLifecycleStatus < ActiveRecord::Migration[8.0]
  def up
    Company.where(lifecycle_status: 1).update_all(lifecycle_status: 0)   # inactive → active
    Company.where(lifecycle_status: 3).update_all(lifecycle_status: 20)  # suspended → suspended(20)
    Company.where(lifecycle_status: 2).update_all(lifecycle_status: 30)  # archived → disabled
    Company.where(lifecycle_status: 4).update_all(lifecycle_status: 30)  # deleted → disabled
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

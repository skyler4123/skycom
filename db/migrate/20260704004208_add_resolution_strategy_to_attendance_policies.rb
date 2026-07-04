class AddResolutionStrategyToAttendancePolicies < ActiveRecord::Migration[8.0]
  def change
    add_column :attendance_policies, :resolution_strategy, :integer, default: 0, null: false
  end
end

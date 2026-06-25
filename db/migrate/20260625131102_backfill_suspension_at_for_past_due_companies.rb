class BackfillSuspensionAtForPastDueCompanies < ActiveRecord::Migration[8.0]
  def up
    Company.where(lifecycle_status: :past_due)
           .where(suspension_at: nil)
           .update_all(suspension_at: Time.current.end_of_month)
  end

  def down
    # No-op: removing suspension_at values would break the suspension logic
  end
end

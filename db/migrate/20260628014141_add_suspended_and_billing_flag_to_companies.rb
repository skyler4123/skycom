class AddSuspendedAndBillingFlagToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :has_unpaid_invoices, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        # Migrate existing past_due (10) → suspended (3)
        Company.where(lifecycle_status: 10).update_all(lifecycle_status: 3, has_unpaid_invoices: true)
      end
    end
  end
end

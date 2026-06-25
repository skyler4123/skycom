class AddHideBillingAlertsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :hide_billing_alerts, :boolean, default: false, null: false
  end
end

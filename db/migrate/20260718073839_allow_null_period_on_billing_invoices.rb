class AllowNullPeriodOnBillingInvoices < ActiveRecord::Migration[8.0]
  def change
    change_column_null :billing_invoices, :period_start, true
    change_column_null :billing_invoices, :period_end, true
  end
end

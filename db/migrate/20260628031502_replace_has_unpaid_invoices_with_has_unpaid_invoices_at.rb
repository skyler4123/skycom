class ReplaceHasUnpaidInvoicesWithHasUnpaidInvoicesAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :companies, :has_unpaid_invoices, :boolean
    add_column :companies, :has_unpaid_invoices_at, :datetime

    reversible do |dir|
      dir.up do
        # Copy suspension_at into has_unpaid_invoices_at for companies that had unpaid invoices
        execute <<~SQL
          UPDATE companies
          SET has_unpaid_invoices_at = suspension_at
          WHERE suspension_at IS NOT NULL
            AND lifecycle_status NOT IN (3, 30)
        SQL
      end
    end
  end
end

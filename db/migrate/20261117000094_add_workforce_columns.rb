class AddWorkforceColumns < ActiveRecord::Migration[8.0]
  def change
    # --- Employees: hire data, cost attribution, bank details for disbursement ---
    add_reference :employees, :cost_center, foreign_key: true, type: :uuid
    add_reference :employees, :job_opening, foreign_key: true, type: :uuid
    add_column :employees, :hire_date, :date
    add_column :employees, :termination_date, :date
    add_column :employees, :employment_type, :string
    add_column :employees, :bank_account, :string
    add_column :employees, :tax_id, :string
    add_index :employees, [ :company_id, :termination_date ]

    # --- Payrolls: approval/payment evidence and the batch that paid them ---
    add_reference :payrolls, :disbursement_batch, foreign_key: true, type: :uuid
    add_reference :payrolls, :cost_center, foreign_key: true, type: :uuid
    add_column :payrolls, :approved_at, :datetime
    add_column :payrolls, :paid_at, :datetime
    add_index :payrolls, [ :company_id, :paid_at ]
  end
end

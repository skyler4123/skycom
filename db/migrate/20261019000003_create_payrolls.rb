# frozen_string_literal: true

class CreatePayrolls < ActiveRecord::Migration[8.1]
  def change
    create_table :payrolls, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.uuid :company_id, null: false
      t.uuid :branch_id
      t.uuid :employee_id, null: false
      t.uuid :attendance_month_id
      t.uuid :payroll_config_id
      t.date :month, null: false
      t.integer :status, null: false, default: 0
      t.text :notes
      t.integer :currency, null: false, default: 840
      t.bigint :base_amount_cents, null: false, default: 0
      t.bigint :allowance_amount_cents, null: false, default: 0
      t.bigint :overtime_amount_cents, null: false, default: 0
      t.bigint :gross_amount_cents, null: false, default: 0
      t.bigint :tax_amount_cents, null: false, default: 0
      t.bigint :deduction_amount_cents, null: false, default: 0
      t.bigint :net_amount_cents, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :company_id
      t.index :branch_id
      t.index :employee_id
      t.index :attendance_month_id
      t.index :payroll_config_id
      t.index [ :company_id, :employee_id, :month ], unique: true
      t.index :month
    end

    add_foreign_key :payrolls, :companies
    add_foreign_key :payrolls, :branches
    add_foreign_key :payrolls, :employees
    add_foreign_key :payrolls, :attendance_months
    add_foreign_key :payrolls, :payroll_configs
  end
end

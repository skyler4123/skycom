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

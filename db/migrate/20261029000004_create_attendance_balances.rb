# frozen_string_literal: true

class CreateAttendanceBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_balances, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.uuid :company_id, null: false
      t.uuid :employee_id, null: false
      t.integer :year, null: false
      t.decimal :entitled_days, precision: 5, scale: 1, null: false, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :company_id
      t.index :employee_id
      t.index [ :employee_id, :year ], unique: true
    end

    add_foreign_key :attendance_balances, :companies
    add_foreign_key :attendance_balances, :employees
  end
end

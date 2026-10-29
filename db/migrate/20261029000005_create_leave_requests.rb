# frozen_string_literal: true

class CreateLeaveRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_requests, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.uuid :company_id, null: false
      t.uuid :branch_id
      t.uuid :employee_id, null: false
      t.uuid :decided_by_id
      t.integer :leave_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :days, precision: 5, scale: 1, null: false, default: 0
      t.text :reason
      t.text :decision_note
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :company_id
      t.index :branch_id
      t.index :employee_id
      t.index :decided_by_id
      t.index :status
      t.index :start_date
      t.index [ :employee_id, :start_date ]
    end

    add_foreign_key :leave_requests, :companies
    add_foreign_key :leave_requests, :branches
    add_foreign_key :leave_requests, :employees
    add_foreign_key :leave_requests, :employees, column: :decided_by_id, on_delete: :nullify
  end
end

# frozen_string_literal: true

class AddManagerToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :manager_id, :uuid
    add_index :employees, :manager_id
    add_foreign_key :employees, :employees, column: :manager_id, on_delete: :nullify
  end
end

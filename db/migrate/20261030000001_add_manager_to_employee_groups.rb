# frozen_string_literal: true

class AddManagerToEmployeeGroups < ActiveRecord::Migration[8.1]
  def change
    add_reference :employee_groups, :manager, type: :uuid, index: true,
                  foreign_key: { to_table: :employees, on_delete: :nullify }
  end
end

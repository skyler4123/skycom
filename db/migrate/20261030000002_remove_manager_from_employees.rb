# frozen_string_literal: true

class RemoveManagerFromEmployees < ActiveRecord::Migration[8.1]
  def change
    remove_reference :employees, :manager, type: :uuid, foreign_key: { to_table: :employees }
  end
end

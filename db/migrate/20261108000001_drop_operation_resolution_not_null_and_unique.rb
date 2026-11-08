# frozen_string_literal: true

class DropOperationResolutionNotNullAndUnique < ActiveRecord::Migration[8.1]
  def change
    change_column_null :operations, :resolution, true

    remove_index :operations, name: "index_operations_on_company_type_resolution", if_exists: true
    add_index :operations, [ :company_id, :operation_type ], unique: true, name: "index_operations_on_company_id_and_operation_type"
  end
end

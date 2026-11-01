# frozen_string_literal: true

# Keeps Import rows intact when the employee who created one is deleted, and
# lets a category be deleted without being blocked by historical imports.
# The creator is still required at creation time by the model validation.
class AdjustImportForeignKeys < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :imports, column: :creator_id
    change_column_null :imports, :creator_id, true
    add_foreign_key :imports, :employees, column: :creator_id, on_delete: :nullify

    remove_foreign_key :imports, column: :category_id
    add_foreign_key :imports, :categories, column: :category_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :imports, column: :creator_id
    change_column_null :imports, :creator_id, false
    add_foreign_key :imports, :employees, column: :creator_id

    remove_foreign_key :imports, column: :category_id
    add_foreign_key :imports, :categories, column: :category_id
  end
end

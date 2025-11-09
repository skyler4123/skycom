class CreateEmployeeGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_groups do |t|
      t.string :name
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end

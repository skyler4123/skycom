class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end

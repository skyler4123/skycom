class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :categories, [ :company_id, :name ]
  end
end

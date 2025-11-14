class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end

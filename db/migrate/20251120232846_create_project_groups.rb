class CreateProjectGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :project_groups do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.string :code
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :project_groups, :discarded_at
  end
end

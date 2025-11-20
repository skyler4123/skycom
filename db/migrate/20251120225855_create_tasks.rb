class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :company, null: false, foreign_key: true
      t.references :task_group, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.string :code
      t.integer :currency
      t.integer :status
      t.integer :business_type
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :tasks, :discarded_at
  end
end

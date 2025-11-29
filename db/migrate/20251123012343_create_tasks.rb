class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks, id: :uuid do |t|
      t.references :company_group, null: false, foreign_key: true, type: :uuid
      t.references :company, null: true, foreign_key: true, type: :uuid

      t.references :task_group, null: false, foreign_key: true, type: :uuid
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

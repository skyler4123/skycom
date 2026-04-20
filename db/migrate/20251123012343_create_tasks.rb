class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid
      t.references :task_group, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :currency_code
      t.integer :lifecycle_status
      t.integer :workflow_status
      t.integer :business_type
      t.datetime :discarded_at
t.jsonb :metadata, default: {}
      t.string :permission_resource_name

      t.timestamps
    end
    add_index :tasks, :discarded_at
  end
end

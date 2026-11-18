class CreateTaskDependencies < ActiveRecord::Migration[8.0]
  def change
    create_table :task_dependencies, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :predecessor_task, null: false, foreign_key: { to_table: :tasks }, type: :uuid
      t.references :successor_task, null: false, foreign_key: { to_table: :tasks }, type: :uuid

      # --- Link ---
      t.integer :dependency_type, null: false, default: 0
      t.integer :lag_days, null: false, default: 0

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :task_dependencies, [ :predecessor_task_id, :successor_task_id ], unique: true, name: "idx_task_dependencies_unique"
  end
end

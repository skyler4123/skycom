class CreateProjectMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :project_milestones, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :invoice, foreign_key: true, type: :uuid

      # --- Milestone ---
      t.string  :name, null: false
      t.text    :description
      t.bigint  :amount_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.date    :due_on
      t.integer :status, null: false, default: 0

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

    add_index :project_milestones, [ :company_id, :project_id, :due_on ]

    add_foreign_key :tasks, :project_milestones, column: :project_milestone_id
  end
end

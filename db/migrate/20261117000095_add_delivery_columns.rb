class AddDeliveryColumns < ActiveRecord::Migration[8.0]
  def change
    # --- Projects: ownership, schedule, budget and billing model ---
    add_reference :projects, :customer, foreign_key: true, type: :uuid
    add_reference :projects, :manager_employee, foreign_key: { to_table: :employees }, type: :uuid
    add_reference :projects, :cost_center, foreign_key: true, type: :uuid
    add_column :projects, :billing_model, :integer, null: false, default: 2
    add_column :projects, :budget_cents, :bigint, null: false, default: 0
    add_column :projects, :planned_start_on, :date
    add_column :projects, :planned_end_on, :date
    add_column :projects, :actual_start_on, :date
    add_column :projects, :actual_end_on, :date
    add_column :projects, :progress_percent, :integer, null: false, default: 0

    # --- Tasks: hierarchy, schedule baseline and effort tracking (Gantt) ---
    add_reference :tasks, :parent_task, foreign_key: { to_table: :tasks }, type: :uuid
    add_reference :tasks, :project_milestone, foreign_key: true, type: :uuid
    add_column :tasks, :planned_start_at, :datetime
    add_column :tasks, :planned_end_at, :datetime
    add_column :tasks, :actual_start_at, :datetime
    add_column :tasks, :actual_end_at, :datetime
    add_column :tasks, :estimated_minutes, :integer, null: false, default: 0
    add_column :tasks, :actual_minutes, :integer, null: false, default: 0
    add_column :tasks, :progress_percent, :integer, null: false, default: 0
    add_index :tasks, [ :company_id, :planned_start_at ]

    # --- Stored files: version chain, integrity and OCR indexing ---
    add_reference :stored_files, :parent_stored_file, foreign_key: { to_table: :stored_files }, type: :uuid
    add_column :stored_files, :version_no, :integer, null: false, default: 1
    add_column :stored_files, :checksum, :string
    add_column :stored_files, :ocr_text, :text
    add_column :stored_files, :ocr_status, :integer
    add_column :stored_files, :indexed_at, :datetime

    # --- Support: SLA clocks and deep links ---
    add_column :tickets, :sla_due_at, :datetime
    add_column :tickets, :first_response_at, :datetime
    add_column :tickets, :resolved_at, :datetime
    add_column :tickets, :escalated_at, :datetime
    add_index :tickets, [ :company_id, :sla_due_at ]

    add_column :company_tickets, :sla_due_at, :datetime
    add_column :company_tickets, :first_response_at, :datetime

    add_column :notifications, :subject_type, :string
    add_column :notifications, :subject_id, :uuid
    add_column :notifications, :group_key, :string
    add_column :notifications, :expires_at, :datetime
    add_index :notifications, [ :subject_type, :subject_id ]

    # --- Companies: reporting currency and multi-entity flags ---
    add_column :companies, :base_currency, :integer, null: false, default: 840
    add_column :companies, :is_legal_entity, :boolean, null: false, default: true
  end
end

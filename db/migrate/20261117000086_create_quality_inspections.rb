class CreateQualityInspections < ActiveRecord::Migration[8.0]
  def change
    create_table :quality_inspections, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :inspector_employee, foreign_key: { to_table: :employees }, type: :uuid

      # --- Inspection ---
      t.integer  :inspection_type, null: false, default: 0
      t.string   :subject_type, null: false
      t.uuid     :subject_id, null: false
      t.integer  :status, null: false, default: 0
      t.datetime :inspected_at
      t.text     :notes

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

    add_index :quality_inspections, [ :subject_type, :subject_id ], name: "idx_quality_inspections_subject"
    add_index :quality_inspections, [ :company_id, :status ]
  end
end

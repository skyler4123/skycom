class CreateRecordComments < ActiveRecord::Migration[8.0]
  def change
    create_table :record_comments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid

      # --- Comment ---
      t.string  :subject_type, null: false
      t.uuid    :subject_id, null: false
      t.text    :body_markdown, null: false
      t.datetime :edited_at

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

    add_index :record_comments, [ :subject_type, :subject_id, :created_at ], name: "idx_record_comments_subject"
    add_index :record_comments, [ :company_id, :created_at ]
  end
end

class CreateCommentMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_mentions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :record_comment, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid

      # --- Read state ---
      t.datetime :read_at

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

    add_index :comment_mentions, [ :record_comment_id, :employee_id ], unique: true
    add_index :comment_mentions, [ :employee_id, :read_at ]
  end
end

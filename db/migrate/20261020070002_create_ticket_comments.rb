class CreateTicketComments < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_comments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :ticket, null: false, foreign_key: true, type: :uuid

      t.uuid :employee_id, null: false
      t.text :message, null: false

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :ticket_comments, [ :company_id, :ticket_id ]
    add_foreign_key :ticket_comments, :employees, column: :employee_id
  end
end
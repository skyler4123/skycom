class CreateCompanyTicketComments < ActiveRecord::Migration[8.0]
  def change
    create_table :company_ticket_comments, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :company_ticket, null: false, foreign_key: true, type: :uuid
      t.references :author, polymorphic: true, null: false, type: :uuid

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

    add_index :company_ticket_comments, [ :company_ticket_id, :created_at ]
    add_index :company_ticket_comments, [ :company_id, :created_at ]
  end
end

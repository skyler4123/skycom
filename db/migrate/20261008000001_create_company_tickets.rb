class CreateCompanyTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :company_tickets, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }, type: :uuid

      t.string :name, null: false
      t.text :description
      t.integer :ticket_category, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.integer :rate
      t.datetime :first_responded_at
      t.datetime :resolved_at

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

    add_index :company_tickets, [ :company_id, :status ]
    add_index :company_tickets, [ :company_id, :assigned_user_id ]
    add_index :company_tickets, [ :company_id, :updated_at ]
  end
end

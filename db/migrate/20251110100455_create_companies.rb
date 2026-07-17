class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :description
      t.string :code
      t.integer :ownership_type
      t.integer :currency
      t.string :registration_number
      t.string :vat_id
      t.string :tax_id
      t.integer :timezone
      t.string :address_line_1
      t.string :city
      t.string :postal_code
      t.integer :country
      t.string :email
      t.string :phone_number
      t.string :website
      t.integer :employee_count
      t.integer :fiscal_year_end_month

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
  end
end

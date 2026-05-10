class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    create_table :branches, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid

      t.string :name
      t.string :description
      t.string :code
      t.integer :ownership_type
      t.integer :currency_code
      t.string :registration_number
      t.string :vat_id
      t.string :tax_id
      t.integer :timezone
      t.string :address_line_1
      t.string :city
      t.string :postal_code
      t.integer :country_code
      t.string :email
      t.string :phone_number
      t.string :website
      t.integer :employee_count
      t.integer :fiscal_year_end_month

      # --- System Fields ---
      t.integer  :lifecycle_status
      t.integer  :workflow_status
      t.integer  :business_type
      t.datetime :expiration_date
      t.jsonb    :metadata,       default: {}
      t.datetime :discarded_at,   index: true
      t.string   :permission_resource_name

      t.timestamps
    end
  end
end

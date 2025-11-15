class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent_company, null: true, foreign_key: { to_table: :companies }
      t.string :name
      t.string :description
      t.integer :status
      t.integer :ownership_type
      t.integer :business_type
      t.string :registration_number
      t.string :vat_id
      t.string :address_line_1
      t.string :city
      t.string :postal_code
      t.string :country
      t.string :email
      t.string :phone_number
      t.string :website
      t.integer :employee_count
      t.integer :fiscal_year_end_month
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :companies, :discarded_at
  end
end

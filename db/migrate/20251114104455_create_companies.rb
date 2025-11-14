class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent_company, null: true, foreign_key: { to_table: :companies }
      t.string :name
      t.string :description
      t.integer :status
      t.integer :kind

      t.timestamps
    end
  end
end

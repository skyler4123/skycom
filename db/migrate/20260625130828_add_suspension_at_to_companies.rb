class AddSuspensionAtToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :suspension_at, :datetime
  end
end

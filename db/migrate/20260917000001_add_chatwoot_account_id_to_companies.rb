class AddChatwootAccountIdToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :chatwoot_account_id, :bigint
    add_index :companies, :chatwoot_account_id, unique: true
  end
end

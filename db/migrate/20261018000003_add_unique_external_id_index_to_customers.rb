class AddUniqueExternalIdIndexToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_index :customers, [ :company_id, :external_id ], unique: true,
              name: "idx_customers_company_external_id_uniq"
  end
end

class AddProfileNameUniqueness < ActiveRecord::Migration[8.0]
  def change
    add_index :employee_profiles, [ :employee_id, :name ], unique: true, name: "idx_employee_profiles_on_employee_and_name"
    add_index :customer_profiles, [ :customer_id, :name ], unique: true, name: "idx_customer_profiles_on_customer_and_name"
    add_index :employee_subprofiles, [ :employee_profile_id, :name ], unique: true, name: "idx_employee_subprofiles_on_profile_and_name"
    add_index :customer_subprofiles, [ :customer_profile_id, :name ], unique: true, name: "idx_customer_subprofiles_on_profile_and_name"
  end
end

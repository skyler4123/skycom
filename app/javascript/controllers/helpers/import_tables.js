// Import target-table picker map. Mirrors IMPORTABLE_RESOURCES in
// config/initializers/constants.rb — the backend re-validates every
// target_table, so this map only drives the UI. Keep both in sync
// (spec/services/imports/schema_resolver_spec.rb asserts the keys match).
// Docs: docs/IMPORT.md
export const IMPORTABLE_RESOURCES = {
  branches: "Branch",
  brands: "Brand",
  customer_profiles: "CustomerProfile",
  customer_subprofiles: "CustomerSubprofile",
  customers: "Customer",
  departments: "Department",
  employee_profiles: "EmployeeProfile",
  employee_subprofiles: "EmployeeSubprofile",
  employees: "Employee",
  facilities: "Facility",
  products: "Product",
  services: "Service",
  suppliers: "Supplier",
  warehouses: "Warehouse"
}

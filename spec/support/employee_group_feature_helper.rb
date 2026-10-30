# frozen_string_literal: true

# Shared setup for the Employee Groups feature specs. Keeps the client cache
# payload and the default category/TableConfig consistent across the four page
# specs without touching production code.
module EmployeeGroupFeatureHelper
  def seed_employee_group_client_cache!(company:, user:, employees: nil)
    employees ||= company.employees.reset

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => company.branches.reset.map { |b| JSON.parse(b.to_json) },
      "departments" => [],
      "roles" => company.roles.reset.map { |r| JSON.parse(r.to_json) }
    )

    payload = {
      user: JSON.parse(user.to_json),
      companies: [ company_data ],
      enums: {},
      employees: employees.map { |e| JSON.parse(e.to_json) }
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  def create_employee_group_category!(company:, properties: {})
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_groups")
    category.update!(name: "Employee Groups") unless category.name == "Employee Groups"

    if properties.any?
      metadata = Seed::CategoryService.build_property_metadata(properties)
      category.default_property_mapping.update!(metadata: { "properties" => metadata })
    end

    category
  end

  def create_employee_group_table_config!(company:, category:, extra_columns: [])
    category.table_configs.destroy_all

    TableConfig.create!(
      company: company,
      category: category,
      property_mapping: category.default_property_mapping,
      resource_name: "employee_groups",
      metadata: { "columns" => [
        { "key" => "name", "name" => "Name", "visible" => true, "align" => "left", "width" => nil, "search" => true },
        { "key" => "code", "name" => "Code", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "branch", "name" => "Branch", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "manager", "name" => "Manager", "visible" => true, "align" => "left", "width" => nil },
        { "key" => "employees_count", "name" => "Members", "visible" => true, "align" => "center", "width" => nil },
        *extra_columns
      ] },
      name: "Employee Groups table config"
    )
  end

  def create_employee_group!(company:, category:, name:, branch: nil, manager: nil, members: [], properties: {})
    group = Seed::EmployeeGroupService.create(
      company: company,
      category: category,
      branch: branch,
      manager: manager,
      name: name
    )
    group.update!(properties) if properties.any?

    ([ manager ] + members).compact.uniq.each do |employee|
      EmployeeEmployeeGroupAppointment.create!(
        company: company,
        employee_group: group,
        employee: employee
      )
    end

    group
  end

  def create_employee!(company:, branch:, name:)
    Seed::EmployeeService.create(company: company, branch: branch, name: name)
  end
end

RSpec.configure do |config|
  config.include EmployeeGroupFeatureHelper
end

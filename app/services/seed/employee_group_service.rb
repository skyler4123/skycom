class Seed::EmployeeGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    manager: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    EmployeeGroup.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      manager: manager,
      email: email,
      name: name,
      description: description
    )
  end

  # Deterministic team lookup used by seeding. Re-running repairs the branch and
  # manager on an existing group instead of creating duplicates.
  def self.find_or_create!(company:, name:, branch: nil, manager: nil)
    employee_group = EmployeeGroup.find_or_initialize_by(company: company, name: name)
    employee_group.branch = branch
    employee_group.manager = manager
    if employee_group.category.nil? && company.present?
      employee_group.category = Seed::CategoryService.find_or_create_for(
        company: company,
        resource_name: EmployeeGroup.model_name.plural
      )
    end
    employee_group.property_mapping ||= employee_group.category&.default_property_mapping
    employee_group.save!
    employee_group
  end

  def self.create(...)
    employee_group = new(...)
    if employee_group.category.nil? && employee_group.company.present?
      employee_group.category = Seed::CategoryService.find_or_create_for(
        company: employee_group.company,
        resource_name: EmployeeGroup.model_name.plural
      )
    end
    if employee_group.property_mapping.nil? && employee_group.category.present?
      employee_group.property_mapping = employee_group.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(employee_group)
    employee_group.save!
    employee_group
  end

  # Idempotent UI bootstrap for the Employee Groups pages. Ensures the default
  # category exists and that its TableConfig carries the fixed core columns
  # (Name/Code/Branch/Manager/Members) plus every configured property column.
  # Existing column settings and the config name are preserved; missing columns
  # are appended only. Called from the controller on index/new so existing
  # companies get a usable page without a data migration.
  def self.ensure_defaults!(company:)
    category = Category.find_or_create_by!(
      company: company,
      resource_name: EmployeeGroup.model_name.plural
    ) do |record|
      record.name = "Employee Groups"
    end

    table_config = category.default_property_mapping.default_table_config
    return category if table_config.nil?

    columns = (table_config.columns || []).dup

    ensure_table_column!(columns, "name", "Name")
    ensure_table_column!(columns, "code", "Code")
    ensure_table_column!(columns, "branch", "Branch")
    ensure_table_column!(columns, "manager", "Manager")
    ensure_table_column!(columns, "employees_count", "Members")

    (category.default_property_mapping.properties || []).each do |property|
      ensure_table_column!(columns, property["key"], property["name"])
    end

    table_config.update!(columns: columns) if columns != table_config.columns

    category
  end

  def self.ensure_table_column!(columns, key, name)
    return if columns.any? { |column| column["key"] == key }

    columns << Seed::TableConfigService.field_hash(key, name)
  end
  private_class_method :ensure_table_column!
end

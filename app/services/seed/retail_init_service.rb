class Seed::RetailInitService
  def self.call(company:)
    new(company:).call
  end

  def initialize(company:)
    @company = company
  end

  def call
    create_roles
    create_categories
    create_table_configs
    configure_retail_permissions
  end

  private

  def create_roles
    RETAIL_INIT_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @company,
        name: role_name,
        description: "#{role_name} role for #{@company.name}"
      )
    end
  end

  def create_categories
    RETAIL_INIT_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        Seed::CategoryService.create(
          company: @company,
          name: name,
          resource_name: resource_name.to_s,
          properties: entry[:properties]
        )
      end
    end
  end

  def create_table_configs
    RETAIL_INIT_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        keys = entry[:visible_columns]
        next unless keys.present?

        category = Category.find_by(company: @company, resource_name: resource_name.to_s, name: name)
        next unless category

        Seed::TableConfigService.create(
          company: @company,
          resource_name: resource_name.to_s,
          category: category,
          property_mapping: category.default_property_mapping,
          columns_metadata: keys.map { |k| field_hash(k, entry[:properties]) },
          name: "#{name} table config"
        )
      end
    end
  end

  def field_hash(key, properties = {})
    label = properties[key.to_sym] || key.humanize
    { "key" => key, "label" => label, "visible" => true,
      "sortable" => true, "align" => "left", "pinned" => nil,
      "width" => nil, "roles" => [], "is_virtual" => false,
      "render_config" => {} }
  end

  def configure_retail_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  def create_all_crud_policies
    crud_actions = %w[create read update delete]

    @company.resource_names.each do |resource|
      crud_actions.each do |action|
        create_policy(resource: resource, action: action)
      end
    end
  end

  def create_policy(resource:, action:)
    policy_name = "Can #{action} #{resource}"
    Policy.find_or_create_by!(
      name: policy_name,
      company: @company,
      resource: resource,
      action: action
    ) do |p|
      p.description = "Allows #{action} operations on #{resource}"
      p.business_type = :operational
      p.lifecycle_status = :active
    end
  end

  def assign_policies_to_roles
    role_definitions = {
      Admin: {
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
        "ShiftTemplate" => { create: true, read: true, update: true, delete: true },
        "AttendanceRecord" => { create: true, read: true, update: true, delete: true },
        "ScheduledShift" => { create: true, read: true, update: true, delete: true },
        "Branch" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "Course" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Department" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Exam" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true },
        "Guest" => { create: true, read: true, update: true, delete: true },
        "Invoice" => { create: true, read: true, update: true, delete: true },
        "Membership" => { create: true, read: true, update: true, delete: true },
        "Order" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: true },
        "Payment" => { create: true, read: true, update: true, delete: true },
        "Policy" => { read: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "TableConfig" => { create: true, read: true, update: true, delete: true },
        "Reservation" => { create: true, read: true, update: true, delete: true },
        "Room" => { create: true, read: true, update: true, delete: true },
        "Service" => { create: true, read: true, update: true, delete: true },
        "Stock" => { create: true, read: true, update: true, delete: true },
        "StockExport" => { create: true, read: true, update: true, delete: true },
        "StockImport" => { create: true, read: true, update: true, delete: true },
        "StockTransfer" => { create: true, read: true, update: true, delete: true },
        "Student" => { create: true, read: true, update: true, delete: true },
        "Table" => { create: true, read: true, update: true, delete: true }
      },
      Manager: {
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
        "ShiftTemplate" => { create: true, read: true, update: true, delete: true },
        "AttendanceRecord" => { create: true, read: true, update: true, delete: true },
        "ScheduledShift" => { create: true, read: true, update: true, delete: true },
        "Branch" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "Course" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Department" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Exam" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true },
        "Guest" => { create: true, read: true, update: true, delete: true },
        "Invoice" => { create: true, read: true, update: true, delete: true },
        "Membership" => { create: true, read: true, update: true, delete: true },
        "Order" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: true },
        "Payment" => { create: true, read: true, update: true, delete: true },
        "Policy" => { read: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "TableConfig" => { create: true, read: true, update: true, delete: true },
        "Reservation" => { create: true, read: true, update: true, delete: true },
        "Room" => { create: true, read: true, update: true, delete: true },
        "Service" => { create: true, read: true, update: true, delete: true },
        "Stock" => { create: true, read: true, update: true, delete: true },
        "StockExport" => { create: true, read: true, update: true, delete: true },
        "StockImport" => { create: true, read: true, update: true, delete: true },
        "StockTransfer" => { create: true, read: true, update: true, delete: true },
        "Student" => { create: true, read: true, update: true, delete: true },
        "Table" => { create: true, read: true, update: true, delete: true }
      },
      Cashier: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Customer" => { create: true, read: true, update: false, delete: false },
        "Brand" => { create: false, read: true, update: false, delete: false }
      },
      Seller: {
        "Order" => { create: true, read: true, update: false, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Customer" => { create: false, read: true, update: false, delete: false },
        "Brand" => { create: false, read: true, update: false, delete: false }
      },
      Security: {
        "Product" => { create: false, read: true, update: false, delete: false },
        "Order" => { create: false, read: true, update: false, delete: false }
      },
      Doctor: {
        "Order" => { read: true, update: true },
        "Service" => { read: true },
        "Brand" => { create: false, read: true, update: false, delete: false },
        "Facility" => { create: true, read: true, update: true, delete: false }
      },
      Therapist: {
        "Order" => { read: true },
        "Facility" => { create: false, read: true, update: false, delete: false }
      },
      Consultant: {
        "Customer" => { create: true, read: true, update: true },
        "Order" => { create: true, read: true },
        "Brand" => { create: false, read: true, update: false, delete: false }
      }
    }

    role_definitions.each do |role_name, resources|
      role = Role.find_by(name: role_name, company: @company)
      next unless role

      resources.each do |resource_name, actions_hash|
        %w[create read update delete].each do |action|
          is_active = actions_hash[action.to_sym]
          policy = Policy.find_by!(company: @company, resource: resource_name, action: action)
          appointment = PolicyAppointment.find_or_create_by!(
            company: @company,
            policy: policy,
            appoint_to: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end

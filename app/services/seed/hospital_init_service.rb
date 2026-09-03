class Seed::HospitalInitService
  HOSPITAL_INIT_ROLES = [
    :Receptionist, :Dentist, :DentalAssistant, :Hygienist, :Manager, :Admin
  ].freeze

  HOSPITAL_INIT_CATEGORIES = {
    branches: {
      "Flagship Clinic" => {
        properties: { property_string_1: "Clinic Director", property_integer_1: "Number of Chairs", property_boolean_1: "Has Emergency Entrance" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Satellite Clinic" => {
        properties: { property_string_1: "Managing Dentist", property_integer_1: "Distance from HQ (km)", property_boolean_1: "Weekend Hours" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Emergency Center" => {
        properties: { property_string_1: "After-Hours Contact", property_integer_1: "Urgent Care Capacity", property_boolean_1: "24/7 Operation" },
        visible_columns: %w[name code property_string_1 workflow_status]
      }
    },
    departments: {
      "Orthodontics" => { properties: { property_string_1: "Lead Orthodontist", property_integer_1: "Active Braces Cases" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Endodontics" => { properties: { property_string_1: "Lead Endodontist", property_integer_1: "Microscopes Available" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Periodontics" => { properties: { property_string_1: "Lead Periodontist", property_boolean_1: "Laser Therapy Available" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Oral Surgery" => { properties: { property_string_1: "Lead Surgeon", property_boolean_1: "IV Sedation Offered" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Pediatrics" => { properties: { property_string_1: "Pediatric Specialist", property_boolean_1: "Child-Friendly Environment" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    employees: {
      "Dentist" => { properties: { property_string_1: "Specialization", property_integer_1: "Years of Experience", property_boolean_1: "Board Certified" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Dental Assistant" => { properties: { property_string_1: "Assigned Dentist", property_boolean_1: "X-Ray Certified" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Receptionist" => { properties: { property_string_1: "Languages Spoken", property_boolean_1: "Insurance Certified" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Hygienist" => { properties: { property_string_1: "Licensed In", property_integer_1: "Daily Patient Cap" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Practice Manager" => { properties: { property_string_1: "Management Focus", property_boolean_1: "Financial Sign-Off Authority" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    customers: {
      "New Patient" => { properties: { property_string_1: "Referral Source", property_boolean_1: "Insurance Verified" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Regular" => { properties: { property_integer_1: "Visit Frequency (months)", property_string_1: "Preferred Dentist" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Insurance" => { properties: { property_string_1: "Insurance Provider", property_string_2: "Policy Number" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "VIP" => { properties: { property_decimal_1: "Lifetime Value", property_string_1: "Account Manager" }, visible_columns: %w[name code property_decimal_1 workflow_status] },
      "Pediatric" => { properties: { property_string_1: "Guardian Name", property_integer_1: "Age" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] }
    },
    services: {
      "Cleaning & Exam" => { properties: { property_integer_1: "Duration (min)", property_decimal_1: "Base Price", property_boolean_1: "Requires X-Ray" }, visible_columns: %w[name code property_integer_1 property_decimal_1 workflow_status] },
      "Filling" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Material Options" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Root Canal" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Tooth Range" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Crown" => { properties: { property_integer_1: "Duration (days)", property_string_1: "Material Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Extraction" => { properties: { property_integer_1: "Duration (min)", property_boolean_1: "Requires Sedation" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Whitening" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Treatment Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Implant" => { properties: { property_integer_1: "Duration (months)", property_string_1: "Implant Brand" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Brace" => { properties: { property_integer_1: "Duration (months)", property_string_1: "Brace Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Invisalign" => { properties: { property_integer_1: "Number of Trays", property_string_1: "Treatment Plan" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Emergency" => { properties: { property_string_1: "Urgency Level", property_boolean_1: "After Hours" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    facilities: {
      "Treatment Room" => { properties: { property_integer_1: "Chair Number", property_boolean_1: "Has X-Ray Panel" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Operatory" => { properties: { property_integer_1: "Room Capacity", property_boolean_1: "Surgical Grade" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "X-ray Room" => { properties: { property_string_1: "Equipment Type", property_boolean_1: "Lead Shielded" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Sterilization Room" => { properties: { property_string_1: "Autoclave Model", property_integer_1: "Cycle Capacity" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Consultation Room" => { properties: { property_string_1: "Purpose", property_boolean_1: "Has TV/Display" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Recovery Area" => { properties: { property_integer_1: "Bed Count", property_boolean_1: "Has Monitoring" }, visible_columns: %w[name code property_integer_1 workflow_status] }
    },
    stock_exports: {
      "Patient Sale" => { properties: { property_string_1: "Patient Name", property_string_2: "Treatment Code" }, visible_columns: %w[name code workflow_status] },
      "Damaged Write-off" => { properties: { property_string_1: "Damage Description", property_string_2: "Reported By" }, visible_columns: %w[name code workflow_status] },
      "Expired Disposal" => { properties: { property_string_1: "Expiry Date Range", property_string_2: "Disposal Method" }, visible_columns: %w[name code workflow_status] }
    },
    stock_imports: {
      "Supplier Purchase" => { properties: { property_string_1: "Supplier Name", property_string_2: "Purchase Order Ref" }, visible_columns: %w[name code workflow_status] },
      "Customer Return" => { properties: { property_string_1: "Return Reason", property_string_2: "Return Authorization" }, visible_columns: %w[name code workflow_status] },
      "Transfer In" => { properties: { property_string_1: "Source Clinic", property_string_2: "Transfer Reference" }, visible_columns: %w[name code workflow_status] }
    },
    orders: {
      "In-Clinic Treatment" => { properties: { property_string_1: "Treating Dentist", property_string_2: "Chair Number" }, visible_columns: %w[name code workflow_status] },
      "Online Booking" => { properties: { property_string_1: "Booking Platform", property_string_2: "Insurance Pre-Auth" }, visible_columns: %w[name code workflow_status] },
      "Emergency Visit" => { properties: { property_string_1: "Triage Level", property_boolean_1: "After Hours Fee Applied" }, visible_columns: %w[name code workflow_status] }
    },
    invoices: {
      "Patient Invoice" => { properties: { property_string_1: "Patient Name", property_boolean_1: "Insurance Claim Filed" }, visible_columns: %w[name code workflow_status] },
      "Insurance Claim" => { properties: { property_string_1: "Insurance Company", property_string_2: "Claim Number" }, visible_columns: %w[name code workflow_status] },
      "Corporate Account" => { properties: { property_string_1: "Company Name", property_decimal_1: "Contract Rate Discount" }, visible_columns: %w[name code workflow_status] }
    }
  }.freeze

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
    configure_hospital_permissions
  end

  private

  def create_roles
    HOSPITAL_INIT_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @company,
        name: role_name,
        description: "#{role_name} role for #{@company.name}"
      )
    end
  end

  def create_categories
    HOSPITAL_INIT_CATEGORIES.each do |resource_name, categories|
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
    HOSPITAL_INIT_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        # Dynamic tables support property_* columns only — default properties are excluded.
        keys = (entry[:visible_columns] || []).grep(/\Aproperty_/)
        keys = entry[:properties].keys.map(&:to_s) if keys.blank? && entry[:properties].present?
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
    name = properties[key.to_sym] || key.humanize
    { "key" => key, "name" => name, "visible" => true,
      "sortable" => true, "align" => "left", "pinned" => nil,
      "width" => nil, "roles" => [], "is_virtual" => false,
      "render_config" => {} }
  end

  def configure_hospital_permissions
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
      Receptionist: {
        "Customer" => { create: true, read: true, update: true, delete: false },
        "Order" => { create: true, read: true, update: false, delete: false },
        "Invoice" => { create: true, read: true, update: false, delete: false },
        "Transaction" => { create: true, read: true, update: false, delete: false },
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: false },
        "Room" => { read: true }
      },
      Dentist: {
        "Customer" => { create: false, read: true, update: true, delete: false },
        "Patient" => { create: false, read: true, update: true, delete: false },
        "Order" => { create: true, read: true, update: true, delete: false },
        "Service" => { read: true },
        "Facility" => { read: true, update: true },
        "Room" => { read: true, update: true },
        "Appointment" => { read: true, update: true }
      },
      DentalAssistant: {
        "Customer" => { read: true, update: true },
        "Patient" => { read: true, update: true },
        "Facility" => { read: true, update: true },
        "Service" => { read: true },
        "Appointment" => { read: true }
      },
      Hygienist: {
        "Customer" => { read: true },
        "Patient" => { read: true },
        "Service" => { read: true },
        "Appointment" => { read: true }
      },
      Manager: {
        "Product" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
        "ShiftTemplate" => { create: true, read: true, update: true, delete: true },
        "ScheduledShift" => { create: true, read: true, update: true, delete: true },
        "AttendancePolicy" => { create: true, read: true, update: true, delete: true },
        "AttendanceLog" => { read: true },
        "AttendanceDay" => { read: true },
        "AttendanceMonth" => { read: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Policy" => { read: true },
        "PaymentMethodAppointment" => { read: true, update: true },
        "Membership" => { create: true, read: true, update: true, delete: true },
        "Reservation" => { create: true, read: true, update: true, delete: true },
        "Room" => { create: true, read: true, update: true, delete: true },
        "Guest" => { create: true, read: true, update: true, delete: true },
        "Course" => { create: true, read: true, update: true, delete: true },
        "Student" => { create: true, read: true, update: true, delete: true },
        "Exam" => { create: true, read: true, update: true, delete: true },
        "Table" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: true },
        "Order" => { create: true, read: true, update: true, delete: true },
        "Invoice" => { create: true, read: true, update: true, delete: true },
        "Transaction" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: true, read: true, update: true, delete: true },
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true },
        "Service" => { create: true, read: true, update: true, delete: true },
        "Branch" => { create: true, read: true, update: true, delete: true },
        "Department" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "TableConfig" => { create: true, read: true, update: true, delete: true },
        "Stock" => { create: true, read: true, update: true, delete: true },
        "StockExport" => { create: true, read: true, update: true, delete: true },
        "StockImport" => { create: true, read: true, update: true, delete: true },
        "StockTransfer" => { create: true, read: true, update: true, delete: true }
      },
      Admin: {
        "Product" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
        "ShiftTemplate" => { create: true, read: true, update: true, delete: true },
        "ScheduledShift" => { create: true, read: true, update: true, delete: true },
        "AttendancePolicy" => { create: true, read: true, update: true, delete: true },
        "AttendanceLog" => { read: true },
        "AttendanceDay" => { read: true },
        "AttendanceMonth" => { read: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Policy" => { read: true },
        "PaymentMethodAppointment" => { read: true, update: true },
        "Membership" => { create: true, read: true, update: true, delete: true },
        "Reservation" => { create: true, read: true, update: true, delete: true },
        "Room" => { create: true, read: true, update: true, delete: true },
        "Guest" => { create: true, read: true, update: true, delete: true },
        "Course" => { create: true, read: true, update: true, delete: true },
        "Student" => { create: true, read: true, update: true, delete: true },
        "Exam" => { create: true, read: true, update: true, delete: true },
        "Table" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Patient" => { create: true, read: true, update: true, delete: true },
        "Order" => { create: true, read: true, update: true, delete: true },
        "Invoice" => { create: true, read: true, update: true, delete: true },
        "Transaction" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: true, read: true, update: true, delete: true },
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true },
        "Service" => { create: true, read: true, update: true, delete: true },
        "Branch" => { create: true, read: true, update: true, delete: true },
        "Department" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "TableConfig" => { create: true, read: true, update: true, delete: true },
        "Stock" => { create: true, read: true, update: true, delete: true },
        "StockExport" => { create: true, read: true, update: true, delete: true },
        "StockImport" => { create: true, read: true, update: true, delete: true },
        "StockTransfer" => { create: true, read: true, update: true, delete: true }
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

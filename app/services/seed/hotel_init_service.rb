class Seed::HotelInitService
  HOTEL_INIT_ROLES = [
    :Receptionist, :Housekeeper, :Concierge, :Chef, :Manager, :Admin
  ].freeze

  HOTEL_INIT_CATEGORIES = {
    branches: {
      "Hotel Tower" => {
        properties: { property_string_1: "Tower Manager", property_integer_1: "Number of Floors", property_boolean_1: "Has Executive Lounge" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Resort Villa" => {
        properties: { property_string_1: "Villa Manager", property_integer_1: "Number of Villas", property_boolean_1: "Has Private Pool" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "City Lodge" => {
        properties: { property_string_1: "Lodge Manager", property_integer_1: "Number of Rooms", property_boolean_1: "24/7 Front Desk" },
        visible_columns: %w[name code property_string_1 workflow_status]
      }
    },
    departments: {
      "Front Office" => { properties: { property_string_1: "Front Office Manager", property_integer_1: "Front Desk Staff" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Housekeeping" => { properties: { property_string_1: "Executive Housekeeper", property_integer_1: "Rooms Per Attendant" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Food & Beverage" => { properties: { property_string_1: "F&B Manager", property_boolean_1: "Room Service Available" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Spa & Wellness" => { properties: { property_string_1: "Spa Manager", property_boolean_1: "Appointment Required" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Maintenance" => { properties: { property_string_1: "Chief Engineer", property_boolean_1: "On-call Nights" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    employees: {
      "Receptionist" => { properties: { property_string_1: "Languages Spoken", property_boolean_1: "Night Shift Certified" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Housekeeper" => { properties: { property_string_1: "Assigned Floor", property_integer_1: "Rooms Per Shift" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Concierge" => { properties: { property_string_1: "Concierge Desk", property_boolean_1: "Tour Booking Authority" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Chef" => { properties: { property_string_1: "Cuisine Specialty", property_integer_1: "Years of Experience" }, visible_columns: %w[name code property_string_1 property_integer_1 workflow_status] },
      "Hotel Manager" => { properties: { property_string_1: "Management Focus", property_boolean_1: "Financial Sign-Off Authority" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    customers: {
      "VIP Guest" => { properties: { property_decimal_1: "Lifetime Value", property_string_1: "Account Manager" }, visible_columns: %w[name code property_decimal_1 workflow_status] },
      "Regular Guest" => { properties: { property_integer_1: "Stays Per Year", property_string_1: "Preferred Room Type" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Corporate Guest" => { properties: { property_string_1: "Company Name", property_string_2: "Contract Number" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Long-stay Guest" => { properties: { property_integer_1: "Nights Booked", property_decimal_1: "Weekly Rate" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Walk-in Guest" => { properties: { property_string_1: "Referral Source", property_boolean_1: "ID Verified" }, visible_columns: %w[name code property_string_1 workflow_status] }
    },
    services: {
      "Accommodation" => { properties: { property_integer_1: "Duration (nights)", property_decimal_1: "Nightly Rate", property_string_1: "Room Type" }, visible_columns: %w[name code property_integer_1 property_decimal_1 workflow_status] },
      "Spa Treatment" => { properties: { property_integer_1: "Duration (min)", property_decimal_1: "Base Price", property_string_1: "Treatment Type" }, visible_columns: %w[name code property_integer_1 property_decimal_1 workflow_status] },
      "Gym Session" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Trainer Required" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Restaurant Dining" => { properties: { property_integer_1: "Party Size", property_string_1: "Meal Period" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Laundry Service" => { properties: { property_integer_1: "Turnaround (hours)", property_decimal_1: "Per Item Price" }, visible_columns: %w[name code property_integer_1 workflow_status] }
    },
    facilities: {
      "Guest Room" => { properties: { property_string_1: "Room Number", property_boolean_1: "Sea View" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Swimming Pool" => { properties: { property_integer_1: "Pool Length (m)", property_boolean_1: "Heated" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Gym Hall" => { properties: { property_integer_1: "Equipment Count", property_boolean_1: "Trainer On Duty" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Spa Room" => { properties: { property_string_1: "Room Theme", property_boolean_1: "Couples Room" }, visible_columns: %w[name code property_string_1 workflow_status] },
      "Restaurant Hall" => { properties: { property_integer_1: "Seating Capacity", property_string_1: "Cuisine Served" }, visible_columns: %w[name code property_integer_1 workflow_status] },
      "Conference Hall" => { properties: { property_integer_1: "Seating Capacity", property_boolean_1: "Has Projector" }, visible_columns: %w[name code property_integer_1 workflow_status] }
    },
    products: {
      "Bottled Water" => {
        properties: { property_string_1: "Bottle Size", property_decimal_1: "Unit Price" },
        visible_columns: %w[name code property_string_1 property_decimal_1 workflow_status]
      },
      "Fast-food" => {
        properties: { property_string_1: "Menu Item", property_decimal_1: "Unit Price" },
        visible_columns: %w[name code property_string_1 property_decimal_1 workflow_status]
      },
      "Minibar Snacks" => {
        properties: { property_string_1: "Snack Type", property_boolean_1: "Refrigerated" },
        visible_columns: %w[name code property_string_1 workflow_status]
      }
    },
    warehouses: {
      # Warehouse semantics are generic for hotels — property slots get numbered labels.
      "Main Warehouse" => {
        properties: { property_string_1: "String Name 1", property_integer_1: "Integer Name 1", property_boolean_1: "Boolean Name 1" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Housekeeping Storage" => {
        properties: { property_string_1: "String Name 2", property_datetime_1: "Datetime Name 1", property_boolean_1: "Boolean Name 2" },
        visible_columns: %w[name code property_string_1 property_datetime_1 workflow_status]
      }
    },
    stocks: {
      "Minibar Stock" => {
        properties: { property_string_1: "String Name 3", property_integer_1: "Integer Name 2", property_boolean_1: "Boolean Name 3" },
        visible_columns: %w[name code product_name category_name warehouse_name quantity pending property_string_1 workflow_status]
      },
      "Housekeeping Supplies" => {
        properties: { property_string_1: "String Name 4", property_datetime_1: "Datetime Name 2" },
        visible_columns: %w[name code product_name category_name warehouse_name quantity property_string_1 property_datetime_1 workflow_status]
      }
    },
    stock_transfers: {
      "Hotel Transfer" => {
        properties: { property_string_1: "String Name 5", property_string_2: "String Name 6" },
        visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status]
      }
    },
    stock_exports: {
      "Guest Sale" => { properties: { property_string_1: "Guest Name", property_string_2: "Folio Reference" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status] },
      "Damaged Write-off" => { properties: { property_string_1: "Damage Description", property_string_2: "Reported By" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status] },
      "Expired Disposal" => { properties: { property_string_1: "Expiry Date Range", property_string_2: "Disposal Method" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status] }
    },
    stock_imports: {
      "Supplier Purchase" => { properties: { property_string_1: "Supplier Name", property_string_2: "Purchase Order Ref" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 property_string_2 workflow_status] },
      "Guest Return" => { properties: { property_string_1: "Return Reason", property_string_2: "Return Authorization" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status] },
      "Transfer In" => { properties: { property_string_1: "Source Branch", property_string_2: "Transfer Reference" }, visible_columns: %w[name code product_name category_name from_name to_name quantity property_string_1 workflow_status] }
    },
    suppliers: {
      "Food & Beverage" => {
        properties: { property_string_1: "Contact Person", property_integer_1: "Lead Time (days)" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Housekeeping Supplies" => {
        properties: { property_integer_1: "Warranty (months)", property_boolean_1: "Preferred Supplier" },
        visible_columns: %w[name code property_integer_1 workflow_status]
      },
      "Linen & Amenities" => {
        properties: { property_decimal_1: "Minimum Order Value", property_boolean_1: "Preferred Supplier" },
        visible_columns: %w[name code property_decimal_1 workflow_status]
      }
    },
    orders: {
      "Room Stay Order" => { properties: { property_string_1: "Room Number", property_string_2: "Guest Name" }, visible_columns: %w[name code workflow_status] },
      "Dining Order" => { properties: { property_string_1: "Table Number", property_string_2: "Server Name" }, visible_columns: %w[name code workflow_status] },
      "Spa Booking Order" => { properties: { property_string_1: "Therapist Name", property_string_2: "Treatment Room" }, visible_columns: %w[name code workflow_status] }
    },
    invoices: {
      "Guest Folio" => { properties: { property_string_1: "Guest Name", property_boolean_1: "Checked Out" }, visible_columns: %w[name code workflow_status] },
      "Corporate Account" => { properties: { property_string_1: "Company Name", property_decimal_1: "Contract Rate Discount" }, visible_columns: %w[name code workflow_status] },
      "Tax Refund Invoice" => { properties: { property_string_1: "Tax Authority", property_decimal_1: "Refund Amount" }, visible_columns: %w[name code workflow_status] }
    },
    purchases: {
      "Food Procurement" => {
        properties: { property_string_1: "Requesting Department", property_string_2: "Reason" },
        visible_columns: %w[name code workflow_status needed_by]
      },
      "Housekeeping Procurement" => {
        properties: { property_string_1: "Supply Category", property_decimal_1: "Budget Cap" },
        visible_columns: %w[name code workflow_status needed_by]
      },
      "Hotel Equipment" => {
        properties: { property_string_1: "Equipment Category", property_integer_1: "Approval Level" },
        visible_columns: %w[name code workflow_status needed_by]
      }
    },
    purchase_items: {
      "Perishable Items" => {
        properties: { property_string_1: "Brand Preference", property_integer_1: "Pack Size" },
        visible_columns: %w[name code unit estimated_unit_price]
      },
      "Amenity Items" => {
        properties: { property_string_1: "Scent Variant", property_boolean_1: "Eco Packaging" },
        visible_columns: %w[name code unit estimated_unit_price]
      },
      "Hotel Equipment Items" => {
        properties: { property_string_1: "Warranty (months)", property_decimal_1: "Unit Cost" },
        visible_columns: %w[name code unit estimated_unit_price]
      }
    },
    events: {
      "Booking" => {
        properties: { property_string_1: "Room Number", property_datetime_1: "Check-in Time", property_datetime_2: "Check-out Time", property_integer_1: "Guest Count" },
        visible_columns: %w[name code property_string_1 property_datetime_1 property_datetime_2 property_integer_1 workflow_status]
      },
      "Conference" => {
        properties: { property_string_1: "Hall Name", property_integer_1: "Attendee Count" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      },
      "Banquet" => {
        properties: { property_string_1: "Menu Package", property_integer_1: "Party Size" },
        visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
      }
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
    create_default_workflows
    create_default_event_configs
    configure_hotel_permissions
  end

  private

  # Category is the bridge to workflows (docs/PURCHASE_WORKFLOW.md): every purchases
  # category gets its own default "Standard Purchase Process" so purchases in the same
  # category always share one workflow. Transitions are Jira-style (ABAC
  # can?(:update, Purchase)) — step names carry the semantics, no per-step enforcement.
  def create_default_workflows
    @company.categories.where(resource_name: "purchases").find_each do |category|
      workflow = Seed::WorkflowService.create(
        company: @company,
        category: category,
        name: "#{category.name} Purchase Process",
        description: "Default purchasing workflow: submit, manager approval, buy, complete.",
        process_type: :purchase_process
      )

      [
        { name: "Submit", position: 1 },
        { name: "Manager Approval", position: 2 },
        { name: "Buy", position: 3 },
        { name: "Complete", position: 4 }
      ].each do |attrs|
        Seed::WorkflowStepService.create(company: @company, workflow: workflow, **attrs)
      end
    end
  end

  def create_roles
    HOTEL_INIT_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @company,
        name: role_name,
        description: "#{role_name} role for #{@company.name}"
      )
    end
  end

  def create_categories
    HOTEL_INIT_CATEGORIES.each do |resource_name, categories|
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
    HOTEL_INIT_CATEGORIES.each do |resource_name, categories|
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
    Seed::TableConfigService.field_hash(key, properties[key.to_sym])
  end

  def configure_hotel_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  # One EventConfig per events category (docs/EVENTS.md): bookings that need
  # goods hold stock; order billing is decoupled for now (all false).
  EVENT_CONFIG_DEFAULTS = {
    "Booking" => { create_stock_pending: true, create_order_on_complete: false },
    "Conference" => { create_stock_pending: false, create_order_on_complete: false },
    "Banquet" => { create_stock_pending: false, create_order_on_complete: false }
  }.freeze

  def create_default_event_configs
    @company.categories.where(resource_name: "events").find_each do |category|
      flags = EVENT_CONFIG_DEFAULTS.fetch(category.name,
        { create_stock_pending: false, create_order_on_complete: false })
      EventConfig.find_or_create_by!(company: @company, category: category) do |config|
        config.create_stock_pending = flags[:create_stock_pending]
        config.create_order_on_complete = flags[:create_order_on_complete]
      end
    end
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
    full_crud = { create: true, read: true, update: true, delete: true }
    role_definitions = {
      Receptionist: {
        "Notification" => { read: true },
        "NotificationTag" => { read: true },
        "Customer" => { create: true, read: true, update: true, delete: false },
        "Order" => { create: true, read: true, update: false, delete: false },
        "Invoice" => { create: true, read: true, update: false, delete: false },
        "Transaction" => { create: true, read: true, update: false, delete: false },
        "Event" => { create: true, read: true, update: true, delete: false },
        "EventConfig" => { read: true },
        "Service" => { read: true },
        "Facility" => { read: true },
        "Purchase" => { create: true, read: true, update: true, delete: false },
        "PurchaseItem" => { create: false, read: true, update: false, delete: false }
      },
      Housekeeper: {
        "Notification" => { read: true },
        "NotificationTag" => { read: true },
        "Facility" => { read: true, update: true },
        "Service" => { read: true },
        "Order" => { read: true },
        "Event" => { read: true }
      },
      Concierge: {
        "Notification" => { read: true },
        "NotificationTag" => { read: true },
        "Customer" => { create: true, read: true, update: true },
        "Order" => { create: true, read: true },
        "Service" => { read: true },
        "Facility" => { read: true },
        "Event" => { create: true, read: true }
      },
      Chef: {
        "Notification" => { read: true },
        "NotificationTag" => { read: true },
        "Order" => { read: true },
        "Service" => { read: true },
        "Facility" => { read: true, update: true },
        "Supplier" => { read: true }
      },
      Manager: {
        "Product" => full_crud,
        "Page" => full_crud,
        "ShiftTemplate" => full_crud,
        "ScheduledShift" => full_crud,
        "AttendanceConfig" => full_crud,
        "AttendanceLog" => { read: true },
        "AttendanceConfigLog" => { read: true },
        "EventConfigLog" => { read: true },
        "TableConfigLog" => { read: true },
        "PermissionLog" => { read: true },
        "AttendanceDay" => { read: true },
        "AttendanceMonth" => { read: true },
        "Brand" => full_crud,
        "Policy" => { read: true },
        "CompanyPaymentMethodAppointment" => { read: true, update: true },
        "Customer" => full_crud,
        "Order" => full_crud,
        "Invoice" => full_crud,
        "Transaction" => full_crud,
        "Employee" => full_crud,
        "Facility" => full_crud,
        "Service" => full_crud,
        "Branch" => full_crud,
        "Department" => full_crud,
        "Category" => full_crud,
        "PropertyMapping" => full_crud,
        "TableConfig" => full_crud,
        "Stock" => full_crud,
        "Supplier" => full_crud,
        "Warehouse" => full_crud,
        "StockExport" => full_crud,
        "StockImport" => full_crud,
        "StockTransfer" => full_crud,
        "StockPending" => full_crud,
        "Event" => full_crud,
        "EventConfig" => full_crud,
        "Notification" => full_crud,
        "NotificationTag" => full_crud,
        "Purchase" => full_crud,
        "PurchaseItem" => full_crud,
        "DiscountGroup" => full_crud,
        "Discount" => full_crud
      },
      Admin: {
        "Product" => full_crud,
        "Page" => full_crud,
        "ShiftTemplate" => full_crud,
        "ScheduledShift" => full_crud,
        "AttendanceConfig" => full_crud,
        "AttendanceLog" => { read: true },
        "AttendanceConfigLog" => { read: true },
        "EventConfigLog" => { read: true },
        "TableConfigLog" => { read: true },
        "PermissionLog" => { read: true },
        "AttendanceDay" => { read: true },
        "AttendanceMonth" => { read: true },
        "Brand" => full_crud,
        "Policy" => { read: true },
        "CompanyPaymentMethodAppointment" => { read: true, update: true },
        "Customer" => full_crud,
        "Order" => full_crud,
        "Invoice" => full_crud,
        "Transaction" => full_crud,
        "Employee" => full_crud,
        "Facility" => full_crud,
        "Service" => full_crud,
        "Branch" => full_crud,
        "Department" => full_crud,
        "Category" => full_crud,
        "PropertyMapping" => full_crud,
        "TableConfig" => full_crud,
        "Stock" => full_crud,
        "Supplier" => full_crud,
        "Warehouse" => full_crud,
        "StockExport" => full_crud,
        "StockImport" => full_crud,
        "StockTransfer" => full_crud,
        "StockPending" => full_crud,
        "Event" => full_crud,
        "EventConfig" => full_crud,
        "Notification" => full_crud,
        "NotificationTag" => full_crud,
        "Purchase" => full_crud,
        "PurchaseItem" => full_crud,
        "DiscountGroup" => full_crud,
        "Discount" => full_crud
      }
    }

    role_definitions.each do |role_name, resources|
      role = Role.find_by(name: role_name, company: @company)
      next unless role

      resources.each do |resource_name, actions_hash|
        %w[create read update delete].each do |action|
          is_active = actions_hash[action.to_sym]
          policy = Policy.find_by!(company: @company, resource: resource_name, action: action)
          appointment = PolicyRoleAppointment.find_or_create_by!(
            company: @company,
            policy: policy,
            role: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end

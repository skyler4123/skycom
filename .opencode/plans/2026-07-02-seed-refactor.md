# Seed Refactor Implementation Plan

**Goal:** Split `Seed::RetailService` into `Seed::RetailInitService` (Phase 1: system records triggered by Company `after_create`) and `Seed::RetailEnrichService` (Phase 2: sample data for seeding).

**Architecture:** Phase 1 constants move to `config/initializers/constants.rb` with `RETAIL_INIT_*` prefix. `Company#setup_owner_records` calls `Seed::RetailInitService.call(company:)` at the end. `Seed::ApplicationService` calls `Seed::RetailEnrichService` instead of `Seed::RetailService`.

**Tech Stack:** Ruby on Rails, ActiveRecord, Seed services

---

### Task 1: Add RETAIL_INIT_* constants to constants.rb

**Files:**
- Modify: `config/initializers/constants.rb`
- Reference: `app/services/seed/retail_service.rb`

- [ ] **Step 1: Read constants.rb end and retail_service.rb constants**

Read the last 10 lines of `config/initializers/constants.rb` to find insertion point. Read `app/services/seed/retail_service.rb` lines 1-20 and the METADATA_CATEGORIES section (~lines 20-933).

- [ ] **Step 2: Append RETAIL_INIT_* constants section to constants.rb**

Add after the SUBSCRIPTION_LIMITS section:

```ruby

# =============================================================================
# Retail Init Defaults
# Used by Seed::RetailInitService to bootstrap a new retail company with
# system records (roles, categories, property_mappings, table_configs).
# =============================================================================

RETAIL_INIT_ROLES = [
  :Manager, :Cashier, :Seller, :Security, :Admin, :Doctor, :Therapist, :Consultant
].freeze

RETAIL_INIT_EMPLOYEE_COUNTS = {
  Manager: 1, Cashier: 10, Seller: 10, Security: 1,
  Admin: 1, Doctor: 3, Therapist: 8, Consultant: 5
}.freeze

RETAIL_INIT_CUSTOMER_COUNTS = { Customer: 50 }.freeze

RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE = :retail

RETAIL_INIT_CLINIC_FACILITIES = [
  "Clinic Room A", "Clinic Room B", "Laser Machine 01", "HIFU Machine"
].freeze

RETAIL_INIT_POPULAR_BRANDS = [
  "Apple", "Samsung", "Nike", "Adidas", "Sony",
  "L'Oréal", "Estée Lauder", "Chanel", "Dior", "Lancôme",
  "Shiseido", "Clarins", "La Mer", "SK-II", "Bobbi Brown",
  "MAC", "NARS", "Urban Decay", "Too Faced", "Benefit",
  "Tarte", "Fenty Beauty", "Huda Beauty", "Kylie Cosmetics", "K-beauty",
  "J-beauty", "The Ordinary", "CeraVe", "Neutrogena", "Olay",
  "Garnier", "Nivea", "Lush", "Bath & Body Works", "Victoria's Secret",
  "Tom Ford", "Gucci", "Prada", "Versace", "Burberry",
  "Dolce & Gabbana", "Yves Saint Laurent", "Armani", "Givenchy", "Bvlgari",
  "Cartier", "Tiffany & Co.", "Rolex", "Omega", "Spotify"
].freeze

RETAIL_INIT_CATEGORIES = {
  products: {
    "Cosmetics" => {
      properties: {
        property_string_1: "Skin Type Suitability",
        property_string_2: "Key Ingredients",
        property_integer_1: "Volume (ml)",
        property_boolean_1: "Organic Certified"
      },
      visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1]
    },
    "Perfumes" => {
      properties: { property_string_1: "Scent Profile / Notes", property_integer_1: "Volume (ml)", property_boolean_1: "Includes Tester Unit" },
      visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
    },
    "Beauty Tools" => {
      properties: { property_string_1: "Power Source", property_integer_1: "Wattage", property_boolean_1: "Rechargeable" },
      visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
    },
    "Makeup" => {
      properties: { property_string_1: "Finish Type", property_string_2: "Shade Range", property_boolean_1: "Long-lasting" },
      visible_columns: %w[name code property_string_1 property_string_2 property_boolean_1]
    },
    "Jewelry" => {
      properties: { property_string_1: "Material", property_decimal_1: "Weight (g)", property_boolean_1: "Hypoallergenic" },
      visible_columns: %w[name code property_string_1 property_decimal_1 property_boolean_1]
    },
    "Accessories" => {
      properties: { property_string_1: "Material", property_boolean_1: "Adjustable" },
      visible_columns: %w[name code property_string_1 property_boolean_1]
    }
  },
  employees: {
    "Management" => {
      properties: { property_integer_1: "Team Size", property_string_1: "Department" },
      visible_columns: %w[name code business_type workflow_status property_integer_1 property_string_1]
    },
    "Sales Specialist" => {
      properties: { property_decimal_1: "Monthly Target", property_integer_1: "Client Portfolio Size" },
      visible_columns: %w[name code business_type workflow_status property_decimal_1 property_integer_1]
    },
    "Cashier" => {
      properties: { property_string_1: "POS Station", property_decimal_1: "Cash Drawer Limit" },
      visible_columns: %w[name code business_type workflow_status property_string_1]
    },
    "Technical Support" => {
      properties: { property_string_1: "Specialization", property_integer_1: "Years of Experience" },
      visible_columns: %w[name code business_type workflow_status property_string_1 property_integer_1]
    },
    "Marketing" => {
      properties: { property_string_1: "Focus Area", property_integer_1: "Campaigns Managed" },
      visible_columns: %w[name code business_type workflow_status property_string_1 property_integer_1]
    }
  },
  branches: {
    "Flagship Store" => {
      properties: {
        property_integer_1: "Maximum Occupancy", property_integer_2: "Number of POS Tills",
        property_integer_3: "Parking Spaces", property_integer_4: "Display Shelves",
        property_boolean_1: "Has Back Office", property_boolean_2: "Has Fitting Rooms",
        property_decimal_1: "Lease Size (sq ft)", property_decimal_2: "Monthly Rent",
        property_string_1: "Store Manager Name", property_string_2: "Operating Hours"
      },
      visible_columns: %w[name code property_string_2 property_integer_1 property_decimal_1 workflow_status]
    },
    "Mall Kiosk" => {
      properties: {
        property_string_5: "Mall Name", property_string_1: "Kiosk Size Category",
        property_string_2: "Foot Traffic Level", property_string_3: "Product Category Focus",
        property_decimal_1: "Monthly Rent", property_decimal_2: "Revenue Target",
        property_integer_1: "Staff Assigned", property_integer_2: "Years in Operation",
        property_boolean_1: "Has Storage Unit", property_boolean_2: "Has POS System"
      },
      visible_columns: %w[name code property_string_5 property_integer_1 workflow_status]
    },
    "Warehouse Distribution" => {
      properties: {
        property_integer_1: "Warehouse Capacity (sq ft)", property_integer_2: "Loading Docks",
        property_integer_3: "Staff Count", property_decimal_1: "Monthly Throughput (tons)",
        property_decimal_2: "Temperature Range", property_boolean_1: "Climate Controlled",
        property_boolean_2: "Has Cold Storage", property_string_1: "Warehouse Manager",
        property_string_2: "Operating Hours", property_datetime_1: "Last Inspection Date"
      },
      visible_columns: %w[name code property_integer_1 property_boolean_1 workflow_status]
    },
    "Pop-up Shop" => {
      properties: {
        property_datetime_1: "Start Date", property_datetime_2: "End Date",
        property_datetime_3: "Last Inventory Count", property_string_1: "Theme / Concept",
        property_string_2: "Location Type", property_string_3: "Target Audience",
        property_decimal_1: "Setup Cost", property_decimal_2: "Expected Revenue",
        property_integer_1: "Staff Assigned", property_boolean_1: "Has Social Media Promotion"
      },
      visible_columns: %w[name code property_string_1 property_datetime_1 property_datetime_2 workflow_status]
    }
  },
  departments: {
    "Operations" => {
      properties: {
        property_string_1: "Scope", property_string_2: "Region", property_integer_1: "Staff Count",
        property_boolean_1: "Is Outsourced", property_decimal_1: "Annual Budget",
        property_decimal_2: "Operational Cost", property_integer_2: "Active Projects",
        property_string_3: "Reporting Manager", property_string_4: "Department Head", property_string_5: "Shift Schedule"
      },
      visible_columns: %w[name code property_string_4 property_integer_1 workflow_status]
    },
    "Human Resources" => {
      properties: {
        property_string_1: "HR Focus", property_string_2: "Recruitment Region",
        property_integer_1: "Employees Managed", property_boolean_1: "Handles Payroll",
        property_decimal_1: "Training Budget", property_decimal_2: "HR Software Cost",
        property_integer_2: "Open Positions", property_string_3: "HR Lead",
        property_string_4: "Benefits Coordinator", property_string_5: "Compliance Officer"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Finance" => {
      properties: {
        property_string_1: "Finance Area", property_string_2: "Reporting Standard",
        property_integer_1: "Accounts Managed", property_boolean_1: "Handles Audits",
        property_decimal_1: "Budget Allocated", property_decimal_2: "Revenue Target",
        property_integer_2: "Quarterly Reports", property_string_3: "CFO",
        property_string_4: "Tax Specialist", property_string_5: "Accounting Method"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    },
    "Customer Service" => {
      properties: {
        property_string_1: "Service Channel", property_string_2: "Support Region",
        property_integer_1: "Agent Count", property_boolean_1: "24/7 Support",
        property_decimal_1: "Monthly Spend", property_decimal_2: "Avg Handle Time (min)",
        property_integer_2: "Daily Tickets", property_string_3: "Service Manager",
        property_string_4: "Escalation Lead", property_string_5: "Tech Stack"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 property_integer_2 workflow_status]
    },
    "Inventory Control" => {
      properties: {
        property_string_1: "Inventory Type", property_string_2: "Stock Region",
        property_integer_1: "SKUs Managed", property_boolean_1: "Uses Barcode System",
        property_decimal_1: "Inventory Value", property_decimal_2: "Monthly Turnover",
        property_integer_2: "Warehouses", property_string_3: "Inventory Manager",
        property_string_4: "Supplier Coordinator", property_string_5: "System Used"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 workflow_status]
    }
  },
  brands: {
    "Luxury" => { properties: { property_string_1: "Tier Level", property_integer_1: "Minimum Order Quantity" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Mass Market" => { properties: { property_string_1: "Target Demographic", property_decimal_1: "Average Price Point" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Indie" => { properties: { property_string_1: "Origin Country", property_boolean_1: "Exclusive Distribution" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Organic" => { properties: { property_string_1: "Certification Type", property_boolean_1: "Cruelty-Free" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Eco-friendly" => { properties: { property_string_1: "Sustainability Rating", property_boolean_1: "Recyclable Packaging" }, visible_columns: %w[name code property_string_1 workflow_status] }
  },
  customers: {
    "Retail VIP" => { properties: { property_integer_1: "Loyalty Points", property_decimal_1: "Credit Limit", property_boolean_1: "Premium Member" }, visible_columns: %w[name code property_integer_1 property_boolean_1 workflow_status] },
    "Regular" => { properties: { property_string_1: "Preferred Category", property_integer_1: "Visit Frequency (monthly)" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Wholesale" => { properties: { property_decimal_1: "Bulk Discount Rate", property_string_1: "Business Type" }, visible_columns: %w[name code property_decimal_1 workflow_status] },
    "Occasional" => { properties: { property_string_1: "Referral Source", property_boolean_1: "Has Made Purchase" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Walk-in" => { properties: { property_boolean_1: "Signed Up For Newsletter", property_string_1: "Interest Area" }, visible_columns: %w[name code workflow_status] }
  },
  services: {
    "Skincare Consultation" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Room Required" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Makeup Artistry" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Skill Level" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Spa Treatment" => { properties: { property_integer_1: "Duration (min)", property_string_1: "Room Required" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Delivery & Installation" => { properties: { property_string_1: "Coverage Area", property_decimal_1: "Base Fee" }, visible_columns: %w[name code property_string_1 workflow_status] },
    "Membership Registration" => { properties: { property_string_1: "Package Name", property_decimal_1: "Monthly Fee" }, visible_columns: %w[name code property_string_1 workflow_status] }
  },
  facilities: {
    "Retail Floor" => { properties: { property_integer_1: "Floor Space (sq ft)", property_string_1: "Department" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Storage Room" => { properties: { property_integer_1: "Capacity (sq ft)", property_boolean_1: "Climate Controlled" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Office Space" => { properties: { property_integer_1: "Seating Capacity", property_boolean_1: "Has Meeting Room" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Break Room" => { properties: { property_integer_1: "Seating Capacity", property_boolean_1: "Has Kitchenette" }, visible_columns: %w[name code workflow_status] },
    "Parking Area" => { properties: { property_integer_1: "Car Spaces", property_integer_2: "Bike Spaces" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Security Station" => { properties: { property_integer_1: "Monitors", property_boolean_1: "Has Alarm System" }, visible_columns: %w[name code workflow_status] }
  },
  warehouses: {
    "Distribution Center" => { properties: { property_integer_1: "Capacity (sq ft)", property_string_1: "Region Served" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Cold Storage" => { properties: { property_integer_1: "Temperature Range (°C)", property_boolean_1: "Humidity Controlled" }, visible_columns: %w[name code property_integer_1 workflow_status] },
    "Fulfillment Hub" => { properties: { property_integer_1: "Processing Capacity (orders/day)", property_string_1: "Service Area" }, visible_columns: %w[name code property_integer_1 workflow_status] }
  },
  stock_transfers: {
    "Inter-Branch Transfer" => { properties: { property_string_1: "Transfer Reason", property_string_2: "Authorized By" }, visible_columns: %w[name code workflow_status] },
    "Emergency Replenishment" => { properties: { property_string_1: "Priority Level", property_string_2: "Approval Status" }, visible_columns: %w[name code workflow_status] }
  },
  stock_exports: {
    "Customer Sale" => { properties: { property_string_1: "Customer Name", property_string_2: "Invoice Reference" }, visible_columns: %w[name code workflow_status] },
    "Damaged Write-off" => { properties: { property_string_1: "Damage Description", property_string_2: "Reported By" }, visible_columns: %w[name code workflow_status] },
    "Expired Disposal" => { properties: { property_string_1: "Expiry Date Range", property_string_2: "Disposal Method" }, visible_columns: %w[name code workflow_status] }
  },
  stock_imports: {
    "Supplier Purchase" => { properties: { property_string_1: "Supplier Name", property_string_2: "Purchase Order Ref" }, visible_columns: %w[name code workflow_status] },
    "Customer Return" => { properties: { property_string_1: "Return Reason", property_string_2: "Return Authorization" }, visible_columns: %w[name code workflow_status] },
    "Transfer In" => { properties: { property_string_1: "Source Branch", property_string_2: "Transfer Reference" }, visible_columns: %w[name code workflow_status] }
  },
  orders: {
    "In-Store Purchase" => { properties: { property_string_1: "POS Terminal ID", property_string_2: "Cashier Name" }, visible_columns: %w[name code workflow_status] },
    "Online Order" => { properties: { property_string_1: "Delivery Method", property_string_2: "Tracking Number" }, visible_columns: %w[name code workflow_status] },
    "Phone Order" => { properties: { property_string_1: "Customer Phone", property_string_2: "Call Duration" }, visible_columns: %w[name code workflow_status] }
  },
  invoices: {
    "B2C Retail Invoice" => { properties: { property_string_1: "Customer Email", property_boolean_1: "Email Sent" }, visible_columns: %w[name code workflow_status] },
    "B2B Corporate Invoice" => { properties: { property_string_1: "Company Name", property_string_2: "Tax ID" }, visible_columns: %w[name code workflow_status] },
    "Tax Refund Invoice" => { properties: { property_string_1: "Tax Authority", property_decimal_1: "Refund Amount" }, visible_columns: %w[name code workflow_status] }
  }
}.freeze
```

- [ ] **Step 3: Run rubocop**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 4: Commit**

```bash
git add config/initializers/constants.rb
git commit -m "refactor: extract RETAIL_INIT_* constants from RetailService to constants.rb"
```

---

### Task 2: Create Seed::RetailInitService

**Files:**
- Create: `app/services/seed/retail_init_service.rb`

Extract Phase 1 from RetailService: create_categories, create_table_configs, setup_roles_and_permissions (with create_all_crud_policies, assign_policies_to_roles, and field_hash).

- [ ] **Step 1: Create app/services/seed/retail_init_service.rb**

```ruby
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
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "TableConfig" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: true, read: true, update: true, delete: false },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true }
      },
      Manager: {
        "Appointment" => { create: true, read: true, update: true, delete: true },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Page" => { create: true, read: true, update: true, delete: true },
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
        "PolicyAppointment" => { create: false, read: true, update: false, delete: false },
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
        actions_hash.each do |action, is_active|
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
```

- [ ] **Step 2: Run rubocop**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 3: Commit**

```bash
git add app/services/seed/retail_init_service.rb
git commit -m "feat: create Seed::RetailInitService for Phase 1 system records"
```

---

### Task 3: Modify Company#setup_owner_records

**Files:**
- Modify: `app/models/company.rb`

- [ ] **Step 1: Add RetailInitService.call at end of setup_owner_records**

Add after line 177 (`Seed::BillingContractService.create(company: self)`):

```ruby
    Seed::RetailInitService.call(company: self)
```

- [ ] **Step 2: Run rubocop**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 3: Commit**

```bash
git add app/models/company.rb
git commit -m "feat: call RetailInitService from Company#setup_owner_records"
```

---

### Task 4: Create Seed::RetailEnrichService

**Files:**
- Create: `app/services/seed/retail_enrich_service.rb`
- Delete: `app/services/seed/retail_service.rb`

- [ ] **Step 1: Read the full retail_service.rb content**

Read all of `app/services/seed/retail_service.rb` to have the complete source.

- [ ] **Step 2: Create app/services/seed/retail_enrich_service.rb**

Copy the full `Seed::RetailService` content and make these changes:

1. Change class name: `class Seed::RetailService` → `class Seed::RetailEnrichService`
2. Remove the 7 class-level constants (they're in constants.rb now)
3. Update all constant references:
   - `COMPANY_GROUP_BUSINESS_TYPE` → `RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE`
   - `METADATA_CATEGORIES` → `RETAIL_INIT_CATEGORIES`
   - `RETAIL_ROLES` → `RETAIL_INIT_ROLES`
   - `EMPLOYEE_COUNTS` → `RETAIL_INIT_EMPLOYEE_COUNTS`
   - `CUSTOMER_COUNTS` → `RETAIL_INIT_CUSTOMER_COUNTS`
   - `POPULAR_BRANDS` → `RETAIL_INIT_POPULAR_BRANDS`
   - `CLINIC_FACILITIES` → `RETAIL_INIT_CLINIC_FACILITIES`
4. Remove from `seeding` method: `create_categories`, `create_table_configs`, `setup_roles_and_permissions`
5. Remove these methods from the class: `create_categories`, `create_table_configs`, `field_hash`, `setup_roles_and_permissions`, `configure_retail_permissions`, `create_all_crud_policies`, `create_policy`, `assign_policies_to_roles`

The `seeding` method should look like:

```ruby
  def seeding
    print_header
    create_retail_company
    create_brands
    create_branches
    create_pages
    create_subscription_plans_for_company
    create_facilities_for_branches
    appoint_payment_methods_to_company
    create_departments_for_company
    create_employees
    assign_employees_to_departments
    create_customers_for_company
    setup_loyalty_programs
    create_inventory
    create_warehouses_for_branches
    create_stocks_for_products
    create_stock_transfers
    create_stock_imports
    create_stock_exports
    create_customer_orders
    create_invoices
    create_billing_data
    print_footer
    true
  end
```

- [ ] **Step 3: Delete old file**

Run: `git rm app/services/seed/retail_service.rb`

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 5: Commit**

```bash
git add app/services/seed/retail_enrich_service.rb
git commit -m "feat: create Seed::RetailEnrichService (Phase 2) from RetailService"
```

---

### Task 5: Update ApplicationService and remaining references

**Files:**
- Modify: `app/services/seed/application_service.rb`
- Modify: `app/services/seed/billing_data_service.rb` (comment)

- [ ] **Step 1: Update application_service.rb**

Replace 3 occurrences of `Seed::RetailService` with `Seed::RetailEnrichService` (lines 50, 52, 60).

- [ ] **Step 2: Update billing_data_service.rb comment**

Change the comment referencing `Seed::RetailService` to `Seed::RetailEnrichService` if present.

- [ ] **Step 3: Search for any remaining references**

Run: `grep -rn "Seed::RetailService" app/ spec/`
Expected: No matches

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop`
Expected: No offenses

- [ ] **Step 5: Commit**

```bash
git add app/services/seed/application_service.rb app/services/seed/billing_data_service.rb
git commit -m "refactor: update remaining RetailService references to RetailEnrichService"
```

---

### Task 6: Run verification

- [ ] **Step 1: Run complete rubocop**

Run: `bin/rubocop`
Expected: 794 files inspected, no offenses

- [ ] **Step 2: Run test suite**

Run: `bundle exec rspec` (or the relevant seed/setup tests)

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: address issues from verification"
```

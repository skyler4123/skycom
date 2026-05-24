class Seed::RetailService
  EMPLOYEE_COUNTS = {
    Manager: 1,
    Cashier: 10,
    Seller: 10,
    Security: 1,
    Admin: 1,
    Doctor: 3,      # Advises & Performs clinical services
    Therapist: 8,   # Performs skin treatments/spa
    Consultant: 5  # Sells products & advises services

  }.freeze

  CUSTOMER_COUNTS = { Customer: 50 }.freeze
  RETAIL_ROLES = (EMPLOYEE_COUNTS.keys).freeze
  COMPANY_GROUP_BUSINESS_TYPE = :retail

  CLINIC_FACILITIES = [ "Clinic Room A", "Clinic Room B", "Laser Machine 01", "HIFU Machine" ].freeze



  METADATA_CATEGORIES = {
    products: {
      "Cosmetics" => {
        properties: {
          property_string_1: "Skin Type Suitability",
          property_string_2: "Key Ingredients",
          property_string_3: "Formulation (e.g., Liquid, Powder)",
          property_integer_1: "Volume (ml)",
          property_integer_2: "Shelf Life (Months)",
          property_boolean_1: "Organic Certified",
          property_boolean_2: "Requires Refrigeration"
        },
        visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1]
      },
      "Perfumes" => {
        properties: {
          property_string_1: "Scent Profile / Notes",
          property_string_2: "Concentration (EDP / EDT)",
          property_integer_1: "Volume (ml)",
          property_boolean_1: "Includes Tester Unit"
        },
        visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
      },
      "Beauty Tools" => {
        properties: {
          property_string_1: "Material Composition",
          property_string_2: "Power Source Type",
          property_integer_1: "Warranty Period (Months)",
          property_boolean_1: "Waterproof Rating"
        },
        visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
      },
      "Makeup" => {
        properties: {
          property_string_1: "Shade / Color Code",
          property_string_2: "Finish (Matte / Dewy)",
          property_integer_1: "Net Weight (g)",
          property_boolean_1: "Vegan Formulation"
        },
        visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
      },
      "Jewelry" => {
        properties: {
          property_string_1: "Material (Gold / Silver)",
          property_string_2: "Gemstone Type",
          property_decimal_1: "Weight (Grams)",
          property_decimal_2: "Purity Carat"
        },
        visible_columns: %w[name code property_string_1 property_decimal_1 property_decimal_2]
      },
      "Accessories" => {
        properties: {
          property_string_1: "Size / Dimensions",
          property_string_2: "Color Palette",
          property_string_3: "Material Type"
        },
        visible_columns: %w[name code property_string_1 property_string_2]
      }
    },

    employees: {
      "Management" => {
        properties: {
          property_string_1: "Corporate Level",
          property_decimal_1: "KPI Target Bonus %",
          property_boolean_1: "Signing Authority"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1 property_boolean_1]
      },
      "Sales Specialist" => {
        properties: {
          property_string_1: "Assigned Product Line",
          property_decimal_1: "Commission Tier %",
          property_integer_1: "Monthly Sales Target"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1 property_integer_1]
      },
      "Cashier" => {
        properties: {
          property_string_1: "POS Station Number",
          property_integer_1: "Assigned Cash Drawer ID"
        },
        visible_columns: %w[name email property_string_1 property_integer_1]
      },
      "Technical Support" => {
        properties: {
          property_string_1: "Certifications",
          property_string_2: "Primary Tech Stack"
        },
        visible_columns: %w[name email property_string_1 property_string_2]
      },
      "Marketing" => {
        properties: {
          property_string_1: "Channel Focus (Digital/Social)",
          property_decimal_1: "Monthly Ad Budget Limit"
        },
        visible_columns: %w[name email property_string_1 property_decimal_1]
      }
    },

    branches: {
      "Flagship Store" => {
        properties: {
          property_integer_1: "Maximum Occupancy Capacity",
          property_integer_2: "Number of POS Tills",
          property_boolean_1: "Has Tax-Free Counter"
        },
        visible_columns: %w[name property_integer_1 property_integer_2 property_boolean_1]
      },
      "Mall Kiosk" => {
        properties: {
          property_string_5: "Mall Unit Number",
          property_decimal_1: "Lease Square Footage"
        },
        visible_columns: %w[name property_string_5 property_decimal_1]
      },
      "Warehouse Distribution" => {
        properties: {
          property_integer_1: "Loading Bay Count",
          property_decimal_1: "Storage Capacity (Cubic Meters)",
          property_boolean_1: "Cold Chain Storage Enabled"
        },
        visible_columns: %w[name property_integer_1 property_decimal_1 property_boolean_1]
      },
      "Pop-up Shop" => {
        properties: {
          property_datetime_1: "Operation Start Date",
          property_datetime_2: "Operation End Date"
        },
        visible_columns: %w[name property_datetime_1 property_datetime_2]
      }
    },

    departments: {
      "Operations" => {
        properties: {
          property_string_1: "Regional Scope",
          property_string_2: "SOP Revision Code"
        },
        visible_columns: %w[name property_string_1]
      },
      "Human Resources" => {
        properties: {
          property_string_1: "ATS Platform Integration",
          property_boolean_1: "Handles Payroll Directly"
        },
        visible_columns: %w[name property_string_1 property_boolean_1]
      },
      "Finance" => {
        properties: {
          property_string_1: "Accounting Standard (IFRS/VAS)",
          property_string_2: "Primary Corporate Bank Account"
        },
        visible_columns: %w[name property_string_1]
      },
      "Customer Service" => {
        properties: {
          property_string_1: "Helpdesk SLA Tier",
          property_string_2: "Support Communication Channels"
        },
        visible_columns: %w[name property_string_1]
      },
      "Inventory Control" => {
        properties: {
          property_string_1: "Audit Cycle Frequency",
          property_boolean_1: "Auto-Reorder Triggers Active"
        },
        visible_columns: %w[name property_string_1 property_boolean_1]
      }
    },

    brands: {
      "Luxury" => {
        properties: {
          property_string_1: "Tier Level",
          property_decimal_1: "Minimum MSRP Markup Margin"
        },
        visible_columns: %w[name property_string_1 property_decimal_1]
      },
      "Mass Market" => {
        properties: {
          property_string_1: "Distribution Channel Model",
          property_integer_1: "Minimum Order Quantity (MOQ)"
        },
        visible_columns: %w[name property_string_1 property_integer_1]
      },
      "Indie" => {
        properties: {
          property_string_1: "Founder Region",
          property_boolean_1: "Consignment Agreement Terms"
        },
        visible_columns: %w[name property_string_1 property_boolean_1]
      },
      "Organic" => {
        properties: {
          property_string_1: "Certification Body Name",
          property_datetime_1: "Certificate Expiration Date"
        },
        visible_columns: %w[name property_string_1 property_datetime_1]
      },
      "Eco-friendly" => {
        properties: {
          property_string_1: "Sustainability Rating",
          property_string_2: "Packaging Material Base"
        },
        visible_columns: %w[name property_string_1 property_string_2]
      }
    },

    customers: {
      "Retail VIP" => {
        properties: {
          property_integer_1: "Current Loyalty Reward Points",
          property_decimal_1: "Fixed Lifetime Discount Percentage",
          property_datetime_1: "VIP Tier Expiration Date"
        },
        visible_columns: %w[name email property_integer_1 property_decimal_1 property_datetime_1]
      },
      "Regular" => {
        properties: {
          property_integer_1: "Visit Frequency Count",
          property_string_1: "Preferred Store Branch"
        },
        visible_columns: %w[name email property_integer_1 property_string_1]
      },
      "Wholesale" => {
        properties: {
          property_string_1: "Tax Identification Number (TIN)",
          property_string_2: "Credit Terms Granted (e.g., Net 30)",
          property_decimal_1: "Credit Line Limit Amount"
        },
        visible_columns: %w[name email property_string_1 property_string_2 property_decimal_1]
      },
      "Occasional" => {
        properties: {
          property_string_1: "Acquisition Campaign Source"
        },
        visible_columns: %w[name email property_string_1]
      },
      "Walk-in" => {
        properties: {
          property_string_1: "General Notes / Behavioral Tags"
        },
        visible_columns: %w[name email property_string_1]
      }
    },

    services: {
      "Skincare Consultation" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_string_1: "Required Analysis Equipment"
        },
        visible_columns: %w[name property_integer_1 property_string_1]
      },
      "Makeup Artistry" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_decimal_1: "Consumables Material Surcharge Cost"
        },
        visible_columns: %w[name property_integer_1 property_decimal_1]
      },
      "Spa Treatment" => {
        properties: {
          property_integer_1: "Duration (Minutes)",
          property_string_1: "Assigned Treatment Room",
          property_boolean_1: "Shower Facilities Required"
        },
        visible_columns: %w[name property_integer_1 property_string_1 property_boolean_1]
      },
      "Delivery & Installation" => {
        properties: {
          property_string_1: "Logistics Vehicle Tier Required",
          property_decimal_1: "Base Distance Rate Buffer Zone"
        },
        visible_columns: %w[name property_string_1 property_decimal_1]
      },
      "Membership Registration" => {
        properties: {
          property_string_1: "Sign-up Welcome Gift Kit Code",
          property_boolean_1: "Requires Physical Card Printing"
        },
        visible_columns: %w[name property_string_1 property_boolean_1]
      }
    },

    facilities: {
      "Retail Floor" => {
        properties: {
          property_decimal_1: "Floor Space (Sqm)",
          property_integer_1: "Maximum Customer Capacity Count"
        },
        visible_columns: %w[name property_decimal_1 property_integer_1]
      },
      "Storage Room" => {
        properties: {
          property_decimal_1: "Temperature Range Ceiling (C)",
          property_decimal_2: "Humidity Target Threshold %",
          property_boolean_1: "Biometric Lock Security Restricting Access"
        },
        visible_columns: %w[name property_decimal_1 property_boolean_1]
      },
      "Office Space" => {
        properties: {
          property_integer_1: "Configured Network Nodes Count",
          property_integer_2: "Desk Capacity Limit"
        },
        visible_columns: %w[name property_integer_1 property_integer_2]
      },
      "Break Room" => {
        properties: {
          property_boolean_1: "Equipped with Refrigerator",
          property_boolean_2: "Water Purifier Installed"
        },
        visible_columns: %w[name property_boolean_1 property_boolean_2]
      },
      "Parking Area" => {
        properties: {
          property_integer_1: "Motorbike Parking Stalls Count",
          property_integer_2: "Car Parking Stalls Count"
        },
        visible_columns: %w[name property_integer_1 property_integer_2]
      },
      "Security Station" => {
        properties: {
          property_integer_1: "CCTV Monitor Matrices Hooked",
          property_string_1: "Emergency Contact Keypad Trunk Line"
        },
        visible_columns: %w[name property_integer_1 property_string_1]
      }
    }
  }.freeze

  RESOURCES = %w[Order Product Employee Customer PolicyAppointment Booking Service Category PropertyMapping TableConfig Brand Facility]

  # An array of popular company/brand names for seeding.
  POPULAR_BRANDS = [
    "Apple", "Samsung", "Google", "Microsoft", "Amazon", "Facebook", "Tesla",
    "Toyota", "Coca-Cola", "McDonald's", "Disney", "Nike", "Adidas", "Louis Vuitton",
    "Gucci", "Mercedes-Benz", "BMW", "Intel", "IBM", "Cisco", "Oracle", "SAP",
    "Accenture", "Deloitte", "PwC", "KPMG", "EY", "GE", "Honda", "Ford", "Pepsi",
    "Starbucks", "IKEA", "H&M", "Zara", "Uniqlo", "L'Oréal", "Gillette", "Pampers",
    "Colgate", "Nescafé", "Red Bull", "Mastercard", "Visa", "American Express",
    "J.P. Morgan", "Goldman Sachs", "Morgan Stanley", "Netflix", "Spotify"
  ].freeze

  def initialize(user:, email: Faker::Internet.email, name: nil)
    @multi_company_owner = user
    @name = name
    @retail = nil
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []
    @services = []
    @warehouses = []
    @product_counter = 0
    @service_counter = 0
    @employee_counter = 0
    @customer_counter = 0
    @facility_counter = 0
    @email = email
    @email_domain = EmailService.new(email).full_domain
    seeding
  end

  def seeding
    print_header

    create_retail_company
    create_categories
    create_table_configs
    create_brands
    create_branches
    create_subscription_plans_for_company
    create_facilities_for_branches
    appoint_payment_methods_to_company
    setup_roles_and_permissions
    create_departments_for_company
    create_employees
    assign_employees_to_departments
    create_customers_for_company
    setup_loyalty_programs
    create_inventory
    create_warehouses_for_branches
    create_stocks_for_products
    setup_clinic_bookings
    create_stock_transfers
    create_stock_imports
    create_stock_exports
    create_customer_orders

    print_footer
    true
  end

  private

  def print_header
    puts "\n\n🛍️  Starting Retail Company Group Seeding..."
    puts "========================================================="
  end

  def print_footer
    puts "\n========================================================="
    puts "🛍️  Retail Company Group Seeding Complete!"
    puts "========================================================="
  end

  def random_category(resource_name)
    Category.where(company: @retail, resource_name: resource_name.to_s).sample
  end

  def create_retail_company
    puts "Creating retail group..."
    @retail = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: @name || "Company #{Company.count + 1}",
      email: @email,
      description: "A group for multiple retail branch branches",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
  end


  def create_categories
    METADATA_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        Seed::CategoryService.create(
          company: @retail,
          name: name,
          resource_name: resource_name.to_s,
          properties: entry[:properties]
        )
      end
    end
  end

  def create_table_configs
    METADATA_CATEGORIES.each do |resource_name, categories|
      categories.each do |name, entry|
        visible_columns = entry[:visible_columns]
        next unless visible_columns.present?

        category = Category.find_by(company: @retail, resource_name: resource_name.to_s, name: name)
        next unless category

        Seed::TableConfigService.create(
          company: @retail,
          resource_name: resource_name.to_s,
          category: category,
          visible_fields: visible_columns,
          name: "#{name} table config"
        )
      end
    end
  end

  def create_brands
    POPULAR_BRANDS.each do |brand_name|
      brand = Seed::BrandService.create(company: @retail, name: brand_name)
      brand.category = random_category(:brands)
      brand.save!
    end
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Branch #{i + 1}",
        description: "Description for Branch #{i + 1}",
        company: @retail
      )
      branch.attach_tag(key: "Branch #{branch.id} Tag")
      branch.address = Seed::AddressService.create
      branch.category = random_category(:branches)
      branch.save!

      @branches << branch
    end
  end



  def create_subscription_plans_for_company(count: 3)
    count.times do |i|
      Seed::SubscriptionPlanService.create(
        company: @retail,
        name: "Plan #{i + 1}",
        duration_days: rand(30..365)
      )
    end
  end

  def create_subscriptions_for_company(count: 3)
    count.times do |i|
      Seed::SubscriptionService.create(
        company: @retail,
        name: "Retail Company Group Subscription #{i + 1}",
        description: "Subscription plan #{i + 1} for #{@retail.name}"
      )
    end
  end

  def create_facilities_for_branches
    @branches.each do |branch|
      facility_count = rand(1..3)
      facility_count.times do |i|
        @facility_counter += 1
        facility = Seed::FacilityService.create(
          company: @retail,
          branch: branch,
          name: "Facility #{@facility_counter}",
          description: "A facility location for #{branch.name}"
        )
        facility.attach_tag(key: "Facility #{facility.id} Tag")
        facility.category = random_category(:facilities)
        facility.save!
        @facilities << facility
      end
    end
  end

  def appoint_payment_methods_to_company
    @branches.each do |branch|
      3.times { Seed::PaymentMethodAppointmentService.create(company: @retail) }
    end
  end

  def setup_roles_and_permissions
    RETAIL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @retail,
        name: role_name,
        description: "#{role_name} role for #{@retail.name}"
      )
    end
    configure_retail_permissions
  end

  def create_departments_for_company
    [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each do |dept_name|
      department = Seed::DepartmentService.create(
        company: @retail,
        name: dept_name,
        description: "Department: #{dept_name}"
      )
      department.attach_tag(key: "Department #{department.id} Tag")
      department.category = random_category(:departments)
      department.save!
      @departments << department
    end
  end

  def create_employees
    @branches.each_with_index do |branch, index|
      branch_employees = []

      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "#{role_name}_#{i + 1}_retail_branch_#{index + 1}@#{@email_domain}",
            system_role: :company_employee
          )
          @employee_counter += 1
          employee = Seed::EmployeeService.create(
            user: user, company: @retail, branch: branch,
            name: "Employee #{@employee_counter}"
          )
          employee.attach_role(role_name)
          employee.category = random_category(:employees)
          employee.save!
          branch_employees << employee
        end
      end

      @employees.concat(branch_employees)
    end
  end

  def assign_employees_to_departments
    @employees.each do |employee|
      Seed::DepartmentAppointmentService.create(
        company: @retail,
        department: @departments.sample,
        appoint_to: employee
      )
    end
  end

  def create_customers_for_company
    @branches.each do |branch|
      CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: "customer_#{i + 1}_#{branch.id}@example.com",
            system_role: :company_customer
          )
          @customer_counter += 1
          customer = Seed::CustomerService.create(
            user: user, company: @retail, branch: branch, name: "Customer #{@customer_counter}"
          )
          customer.category = random_category(:customers)
          customer.save!
          @customers << customer
        end
      end
    end
  end

  def setup_loyalty_programs
    @branches.each do |branch|
      2.times do |i|
        lp = Seed::CustomerGroupService.create(
          company: @retail, branch: branch, name: "Loyalty Program #{i + 1} - #{branch.name}"
        )
        @loyalty_programs << lp

        branch_customers = @customers.select { |c| c.branch_id == branch.id }
        branch_customers.sample(10).each do |customer|
          Seed::CustomerGroupAppointmentService.create(company: @retail, customer_group: lp, appoint_to: customer)
        end
      end
    end
  end

  def create_inventory
    @branches.each do |branch|
      # 1. Seed 14 Products per branch with index-based naming
      14.times do
        @product_counter += 1
        product = Seed::ProductService.create(
          company: @retail,
          branch: branch,
          name: "Product #{@product_counter}",
          description: "High-quality skincare product"
        )
        product.category = random_category(:products)
        product.save!
        @products << product
      end

      # 2. Seed 5 Services per branch with index-based naming
      5.times do
        @service_counter += 1
        service = Seed::ServiceService.create(
          company: @retail,
          branch: branch,
          name: "Service #{@service_counter}",
          duration: [ 30, 45, 60, 90 ].sample
        )
        service.category = random_category(:services)
        service.save!
        @services << service
      end
    end
  end

  def create_warehouses_for_branches
    @branches.each do |branch|
      warehouse = Seed::WarehouseService.create(
        company: @retail,
        branch: branch,
        name: "#{branch.name} Warehouse",
        business_type: :distribution
      )

      @warehouses ||= []
      @warehouses << warehouse
    end
  end

  def create_stocks_for_products
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each do |product|
        Seed::StockService.create(
          warehouse: warehouse,
          product_id: product.id,
          quantity: rand(50..200),
          name: product.name
        )
      end
    end
  end

  def setup_clinic_bookings
    puts "Setting up clinic resources and sample bookings..."
    @branches.each do |branch|
      # Create physical resources (Rooms/Machines)
      branch_resources = CLINIC_FACILITIES.map do |res_name|
        Seed::FacilityService.create(
          company: @retail,
          branch: branch,
          name: "#{branch.name} - #{res_name}")
      end

      # Create some sample bookings
      doctors = @employees.select { |e| e.branch_id == branch.id && e.user.metadata["role"] == "Doctor" }
      customers = @customers.select { |c| c.branch_id == branch.id }
      services = @services.select { |s| s.branch_id == branch.id }

      3.times do |i|
        next if doctors.empty? || customers.empty?

        Seed::BookingService.create(
          company: @retail,
          branch: branch,
          booking_resource: branch_resources.sample,
          appoint_from: doctors.sample,   # Performed by Doctor
          appoint_to: customers.sample,   # For Customer
          appoint_for: services.sample,    # The Service
          appoint_by: @employees.sample,   # Booked by Staff
          name: "Clinic Appointment ##{i+1}",
          lifecycle_status: :active,
          workflow_status: :confirmed
        )
      end
    end
  end

  def create_stock_transfers
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each do |product|
        stock = Stock.find_by(name: product.name, warehouse: warehouse)
        next unless stock

        Seed::StockTransferService.create(
          company: @retail,
          branch: warehouse.branch,
          product: product,
          appoint_from: warehouse,
          appoint_to: warehouse.branch,
          quantity: stock.quantity,
          workflow_status: :completed,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_stock_imports
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockImportService.create(
          company: @retail,
          branch: branch,
          product: product,
          code: "STKIM-#{SecureRandom.hex(4).upcase}",
          quantity: rand(10..100),
          business_type: StockImport.business_types.keys.sample,
          workflow_status: StockImport.workflow_statuses.keys.sample,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_stock_exports
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockExportService.create(
          company: @retail,
          branch: branch,
          product: product,
          code: "STKEX-#{SecureRandom.hex(4).upcase}",
          quantity: rand(5..50),
          business_type: StockExport.business_types.keys.sample,
          workflow_status: StockExport.workflow_statuses.keys.sample,
          lifecycle_status: :active
        )
      end
    end
  end

  def create_customer_orders
    @branches.each do |branch|
      branch_customers = @customers.select { |c| c.branch_id == branch.id }
      next if branch_customers.empty?

      5.times do |i|
        customer = branch_customers.sample
        order = Seed::OrderService.create(
          company: @retail, branch: branch, customer: customer, name: "Order #{i + 1} for #{customer.name}"
        )
        attach_items_to_order(branch, order)
      end
    end
  end

  def attach_items_to_order(branch, order)
    # Attach Products
    branch_products = @products.select { |p| p.branch_id == branch.id }
    branch_products.sample(rand(2..3)).each do |product|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(10.0..100.0).round(2), total_price: 0)
    end

    # Attach Services
    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..200.0).round(2), total_price: 0)
    end
  end

  def configure_retail_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  def create_all_crud_policies
    crud_actions = %w[create read update delete]

    RESOURCES.each do |resource|
      crud_actions.each do |action|
        create_policy(resource: resource, action: action)
      end
    end
  end

  def all_actions
    %w[create read update delete]
  end

  def create_policy(resource:, action:)
    policy_name = "Can #{action} #{resource}"
    Policy.find_or_create_by!(
      name: policy_name,
      company: @retail,
      resource: resource,
      action: action
    ) do |p|
      p.description = "Allows #{action} operations on #{resource}"
      p.business_type = :operational
      p.lifecycle_status = :active
      p.branch_id = @branches.first.id
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
        "PolicyAppointment" => { create: true, read: true, update: true, delete: false },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true }
      },
      Manager: {
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: false, read: true, update: false, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "Category" => { create: true, read: true, update: true, delete: true },
        "PropertyMapping" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: false, read: true, update: false, delete: false },
        "Brand" => { create: true, read: true, update: true, delete: true },
        "Facility" => { create: true, read: true, update: true, delete: true }
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
        "Booking" => { create: true, read: true, update: true },
        "Service" => { read: true },
        "Brand" => { create: false, read: true, update: false, delete: false },
        "Facility" => { create: true, read: true, update: true, delete: false }
      },
      Therapist: {
        "Booking" => { read: true, update: true },
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
      role = Role.find_by(name: role_name, company: @retail)
      next unless role

      resources.each do |resource_name, actions_hash|
        actions_hash.each do |action, is_active|
          policy = Policy.find_by!(company: @retail, resource: resource_name, action: action)
          appointment = PolicyAppointment.find_or_create_by!(
            company: @retail,
            policy: policy,
            appoint_to: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end

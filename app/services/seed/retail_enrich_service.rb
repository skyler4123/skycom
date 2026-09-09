class Seed::RetailEnrichService
  RETAIL_ENRICH_EMPLOYEE_COUNTS = {
    Manager: 1,
    Cashier: 10,
    Seller: 10,
    Security: 1,
    Admin: 1,
    Doctor: 3,
    Therapist: 8,
    Consultant: 5
  }.freeze

  RETAIL_ENRICH_CUSTOMER_COUNTS = { Customer: 50 }.freeze

  RETAIL_ENRICH_CLINIC_FACILITIES = [
    "Clinic Room A", "Clinic Room B", "Laser Machine 01", "HIFU Machine"
  ].freeze

  RETAIL_ENRICH_POPULAR_BRANDS = [
    "Apple", "Samsung", "Google", "Microsoft", "Amazon", "Facebook", "Tesla",
    "Toyota", "Coca-Cola", "McDonald's", "Disney", "Nike", "Adidas", "Louis Vuitton",
    "Gucci", "Mercedes-Benz", "BMW", "Intel", "IBM", "Cisco", "Oracle", "SAP",
    "Accenture", "Deloitte", "PwC", "KPMG", "EY", "GE", "Honda", "Ford", "Pepsi",
    "Starbucks", "IKEA", "H&M", "Zara", "Uniqlo", "L'Oréal", "Gillette", "Pampers",
    "Colgate", "Nescafé", "Red Bull", "Mastercard", "Visa", "American Express",
    "J.P. Morgan", "Goldman Sachs", "Morgan Stanley", "Netflix", "Spotify"
  ].freeze

  def initialize(user:, email: Faker::Internet.email, name: nil, company: nil,
                 country: nil, currency: nil, timezone: nil,
                 address_line_1: nil, city: nil, postal_code: nil)
    @multi_company_owner = user
    @name = name || company&.name
    @country = country || company&.country || :us
    @currency = currency || company&.currency || :usd
    @timezone = timezone || company&.timezone || :minus_5
    @address_line_1 = address_line_1
    @city = city
    @postal_code = postal_code
    @retail = company
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []
    @services = []
    @warehouses = []
    @pages = []
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

    create_retail_company unless @retail
    create_brands
    create_branches
    create_pages
    create_subscription_plans_for_company
    create_facilities_for_branches
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
    create_shifts
    create_attendance_policies
    create_attendance_event_data
    seed_credit_data

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

  def create_retail_company
    puts "Creating retail group..."
    @retail = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: @name || "Company #{Company.count + 1}",
      email: @email,
      description: "A group for multiple retail branch branches",
      business_type: RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE,
      country: @country,
      currency: @currency,
      timezone: @timezone,
      address_line_1: @address_line_1,
      city: @city,
      postal_code: @postal_code
    )
  end

  def create_brands
    RETAIL_ENRICH_POPULAR_BRANDS.each do |brand_name|
      Seed::BrandService.create(company: @retail, name: brand_name)
    end
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    branch_categories = Category.where(company: @retail, resource_name: "branches").to_a
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Branch #{i + 1}",
        description: "Description for Branch #{i + 1}",
        company: @retail,
        category: branch_categories[i % branch_categories.length]
      )
      branch.attach_tag(key: "Branch #{branch.id} Tag")
      branch.address = Seed::AddressService.create(country: @country)
      branch.save!

      @branches << branch
    end
  end

  def create_pages
    puts "Creating pages for each branch..."
    @branches.each do |branch|
      Seed::PageService.create(
        company: @retail,
        branch: branch,
        name: "Retail Cashier",
        target_role: :retail_cashier,
        target_resolution: :desktop_widescreen,
        metadata: { "layout_manifest" => {
          grid_columns: 12,
          default_sidebar: "customer_loyalty_panel",
          enabled_components: [
            { id: "barcode_listener_daemon", position: "background" },
            { id: "product_search_matrix", position: "span-8", items_per_row: 6 },
            { id: "checkout_summary_card", position: "span-4" }
          ],
          features: {
            quick_cash_buttons: [ 10000, 20000, 50000, 100000, 200000, 500000 ],
            gift_card_redemption: true
          }
        } }
      )

      Seed::PageService.create(
        company: @retail,
        branch: branch,
        name: "Retail Store Manager",
        target_role: :retail_store_manager,
        target_resolution: :desktop_widescreen,
        metadata: { "layout_manifest" => {
          grid_columns: 12,
          default_sidebar: "analytics_panel",
          enabled_components: [
            { id: "sales_kpi_dashboard", position: "span-6" },
            { id: "inventory_alerts", position: "span-6" },
            { id: "staff_on_duty", position: "span-4" },
            { id: "daily_revenue_chart", position: "span-8" }
          ],
          features: {
            approve_discounts: true,
            view_profit_margins: true,
            export_reports: true
          }
        } }
      )
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
    facility_categories = Category.where(company: @retail, resource_name: "facilities").order(:id).to_a
    @branches.each do |branch|
      facility_count = rand(1..3)
      facility_count.times do |i|
        @facility_counter += 1
        facility = Seed::FacilityService.create(
          company: @retail,
          branch: branch,
          category: round_robin(facility_categories, @facility_counter - 1),
          name: "Facility #{@facility_counter}",
          description: "A facility location for #{branch.name}"
        )
        facility.attach_tag(key: "Facility #{facility.id} Tag")
        facility.save!
        @facilities << facility
      end
    end
  end

  def create_departments_for_company
    dept_categories = Category.where(company: @retail, resource_name: "departments").to_a
    [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each_with_index do |dept_name, i|
      department = Seed::DepartmentService.create(
        company: @retail,
        name: dept_name,
        description: "Department: #{dept_name}",
        category: dept_categories[i % dept_categories.length]
      )
      department.attach_tag(key: "Department #{department.id} Tag")
      department.save!
      @departments << department
    end
  end

  def create_employees
    @branches.each_with_index do |branch, index|
      branch_employees = []

      RETAIL_ENRICH_EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          email = "#{role_name}_#{i + 1}_retail_branch_#{index + 1}@#{@email_domain}"
          next if User.exists?(email: email)
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: email,
            system_role: :company_employee
          )
          @employee_counter += 1
          employee = Seed::EmployeeService.create(
            user: user, company: @retail, branch: branch,
            name: "Employee #{@employee_counter}"
          )
          employee.attach_role(role_name)
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
      RETAIL_ENRICH_CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          email = "customer_#{i + 1}_#{branch.id}@example.com"
          next if User.exists?(email: email)
          user = Seed::UserService.create(
            parent_user: @multi_company_owner,
            email: email,
            system_role: :company_customer
          )
          @customer_counter += 1
          customer = Seed::CustomerService.create(
            user: user, company: @retail, branch: branch, name: "Customer #{@customer_counter}"
          )
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
    service_categories = Category.where(company: @retail, resource_name: "services").order(:id).to_a
    @branches.each do |branch|
      14.times do
        @product_counter += 1
        product = Seed::ProductService.create(
          company: @retail,
          branch: branch,
          name: "Product #{@product_counter}",
          description: "High-quality skincare product"
        )
        @products << product
      end

      5.times do
        @service_counter += 1
        service = Seed::ServiceService.create(
          company: @retail,
          branch: branch,
          category: round_robin(service_categories, @service_counter - 1),
          name: "Service #{@service_counter}",
          duration: [ 30, 45, 60, 90 ].sample
        )
        @services << service
      end
    end
  end

  def create_warehouses_for_branches
    warehouse_categories = Category.where(company: @retail, resource_name: "warehouses").order(:id).to_a
    @branches.each_with_index do |branch, i|
      warehouse = Seed::WarehouseService.create(
        company: @retail,
        branch: branch,
        category: round_robin(warehouse_categories, i),
        name: "#{branch.name} Warehouse",
        business_type: :distribution
      )

      @warehouses ||= []
      @warehouses << warehouse
    end
  end

  def create_stocks_for_products
    stock_categories = Category.where(company: @retail, resource_name: "stocks").order(:id).to_a
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each_with_index do |product, i|
        Seed::StockService.create(
          warehouse: warehouse,
          product_id: product.id,
          category: round_robin(stock_categories, i),
          quantity: rand(50..200),
          pending: 0,
          name: product.name
        )
      end
    end
  end

  def create_stock_transfers
    transfer_categories = Category.where(company: @retail, resource_name: "stock_transfers").order(:id).to_a
    @warehouses.each do |warehouse|
      warehouse_products = @products.select { |p| p.branch_id == warehouse.branch_id }
      warehouse_products.each_with_index do |product, i|
        stock = Stock.find_by(name: product.name, warehouse: warehouse)
        next unless stock

        Seed::StockTransferService.create(
          company: @retail,
          category: round_robin(transfer_categories, i),
          branch: warehouse.branch,
          warehouse: warehouse,
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
    import_categories = Category.where(company: @retail, resource_name: "stock_imports").order(:id).to_a
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each_with_index do |product, i|
        Seed::StockImportService.create(
          company: @retail,
          category: round_robin(import_categories, i),
          branch: branch,
          warehouse: branch_warehouse,
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
    export_categories = Category.where(company: @retail, resource_name: "stock_exports").order(:id).to_a
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each_with_index do |product, i|
        Seed::StockExportService.create(
          company: @retail,
          category: round_robin(export_categories, i),
          branch: branch,
          warehouse: branch_warehouse,
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
    order_categories = Category.where(company: @retail, resource_name: "orders").order(:id).to_a
    @branches.each do |branch|
      branch_customers = @customers.select { |c| c.branch_id == branch.id }
      next if branch_customers.empty?

      5.times do |i|
        customer = branch_customers.sample
        order = Seed::OrderService.create(
          company: @retail, branch: branch, customer: customer,
          category: round_robin(order_categories, i),
          name: "Order #{i + 1} for #{customer.name}"
        )
        attach_items_to_order(branch, order)
      end
    end
  end

  def attach_items_to_order(branch, order)
    branch_products = @products.select { |p| p.branch_id == branch.id }
    branch_products.sample(rand(2..3)).each do |product|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(10.0..100.0).round(2), total_price: 0)
    end

    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..200.0).round(2), total_price: 0)
    end
  end

  # Picks a seeded category deterministically so EVERY category of a resource
  # gets records (including the first one, which every index page defaults to)
  # — random_for() left sparse resources (warehouses, stock docs, invoices, …)
  # with empty first categories depending on seed luck.
  def round_robin(categories, index)
    return nil if categories.blank?
    categories[index % categories.length]
  end

  def create_invoices
    puts "Creating invoices for orders..."
    invoice_categories = Category.where(company: @retail, resource_name: "invoices").order(:id).to_a
    @branches.each do |branch|
      branch_orders = Order.where(company: @retail, branch: branch)
      next if branch_orders.empty?

      branch_orders.sample(rand(3..5)).each_with_index do |order, i|
        Seed::InvoiceService.create(order: order, category: round_robin(invoice_categories, i))
      end
    end
    puts "  -> #{Invoice.where(company: @retail).count} invoices created"
  end

  def create_shifts
    puts "Creating shift templates and schedules..."
    templates = []
    @branches.each do |branch|
      [ { name: "Morning", start: "07:00", end: "15:00" },
        { name: "Afternoon", start: "15:00", end: "23:00" },
        { name: "Night", start: "23:00", end: "07:00" }
      ].each do |shift_data|
        template = Seed::ShiftTemplateService.create(
          company: @retail, branch: branch,
          name: shift_data[:name],
          start_time: shift_data[:start],
          end_time: shift_data[:end],
          policy_type: "fixed",
          full_day_minutes: 480
        )
        templates << template
      end
    end

    # Create scheduled shifts for employees
    @employees.each do |employee|
      template = templates.select { |t| t.branch_id == employee.branch_id }.sample
      next unless template

      date = Date.current + rand(0..7).days
      ScheduledShift.create!(
        company: @retail, branch: employee.branch, employee: employee,
        shift_template: template, work_date: date,
        expected_start_at: date.to_time.change(hour: template.start_time.hour, min: template.start_time.min),
        expected_end_at: date.to_time.change(hour: template.end_time.hour, min: template.end_time.min),
        status: :scheduled
      )
    end
  end

  def create_attendance_policies
    puts "Creating attendance policies..."
    @branches.each do |branch|
      AttendancePolicy.create!(
        company: @retail, branch: branch,
        latitude: 10.773, longitude: 106.694,
        allowed_radius_meters: 100
      )
    end
  end

  def create_attendance_event_data
    puts "Creating attendance event data..."

    @employees.each do |employee|
      next unless employee.branch

      template = ShiftTemplate.where(company: @retail, branch: employee.branch).sample
      next unless template

      # Create past shifts for the last 14 days
      (1..14).each do |day_offset|
        date = Date.current - day_offset.days
        next if date.saturday? || date.sunday? # Skip weekends

        expected_start = date.to_time.change(hour: template.start_time.hour, min: template.start_time.min)
        expected_end = date.to_time.change(hour: template.end_time.hour, min: template.end_time.min)

        ScheduledShift.create!(
          company: @retail, branch: employee.branch, employee: employee,
          shift_template: template, work_date: date,
          expected_start_at: expected_start, expected_end_at: expected_end,
          status: :completed
        )

        # Simulate check-in (5-15 min early)
        grace = rand(5..15)
        check_in = expected_start - grace.minutes

        # Simulate check-out (on time or slightly late)
        check_out = expected_end + rand(0..10).minutes

        AttendanceLog.create!(
          company: @retail, branch: employee.branch, employee: employee,
          log_type: "check_in", logged_at: check_in
        )
        AttendanceLog.create!(
          company: @retail, branch: employee.branch, employee: employee,
          log_type: "check_out", logged_at: check_out
        )
      end
    end

    # Run resolution engine
    puts "  -> Running daily resolution..."
    resolved_dates = (1..14).map { |i| Date.current - i.days }.reject { |d| d.saturday? || d.sunday? }
    @employees.each do |emp|
      resolved_dates.each do |date|
        Attendance::DailyResolutionService.new.call(employee: emp, date: date)
      rescue => e
        Rails.logger.warn("Resolution failed for #{emp.id} on #{date}: #{e.message}")
      end
    end
  end

  def seed_credit_data
    puts "Seeding credit data..."
    Seed::CreditDataService.create(company: @retail)
  end
end

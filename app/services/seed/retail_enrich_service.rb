class Seed::RetailEnrichService
  def initialize(user:, email: Faker::Internet.email, name: nil,
                 country_code: :us, currency_code: :usd, timezone: :minus_5,
                 address_line_1: nil, city: nil, postal_code: nil)
    @multi_company_owner = user
    @name = name
    @country_code = country_code
    @currency_code = currency_code
    @timezone = timezone
    @address_line_1 = address_line_1
    @city = city
    @postal_code = postal_code
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
      country_code: @country_code,
      currency_code: @currency_code,
      timezone: @timezone,
      address_line_1: @address_line_1,
      city: @city,
      postal_code: @postal_code
    )
  end

  def create_brands
    RETAIL_INIT_POPULAR_BRANDS.each do |brand_name|
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
      branch.address = Seed::AddressService.create(country_code: @country_code)
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
        layout_manifest: {
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
        }
      )

      Seed::PageService.create(
        company: @retail,
        branch: branch,
        name: "Retail Store Manager",
        target_role: :retail_store_manager,
        target_resolution: :desktop_widescreen,
        layout_manifest: {
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
        }
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

      RETAIL_INIT_EMPLOYEE_COUNTS.each do |role_name, count|
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
      RETAIL_INIT_CUSTOMER_COUNTS.each do |role_name, count|
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
          name: "Service #{@service_counter}",
          duration: [ 30, 45, 60, 90 ].sample
        )
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
          reorder: rand(10..30),
          name: product.name
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
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockImportService.create(
          company: @retail,
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
    @branches.each do |branch|
      branch_products = @products.select { |p| p.branch_id == branch.id }
      next if branch_products.empty?

      branch_warehouse = @warehouses.find { |w| w.branch_id == branch.id }
      branch_products.sample(rand(2..4)).each do |product|
        Seed::StockExportService.create(
          company: @retail,
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
    branch_products = @products.select { |p| p.branch_id == branch.id }
    branch_products.sample(rand(2..3)).each do |product|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(10.0..100.0).round(2), total_price: 0)
    end

    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(company: @retail, order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..200.0).round(2), total_price: 0)
    end
  end

  def create_invoices
    puts "Creating invoices for orders..."
    @branches.each do |branch|
      branch_orders = Order.where(company: @retail, branch: branch)
      next if branch_orders.empty?

      branch_orders.sample(rand(3..5)).each do |order|
        Seed::InvoiceService.create(order: order)
      end
    end
    puts "  -> #{Invoice.where(company: @retail).count} invoices created"
  end

  def create_billing_data
    puts "Generating 7 days of billing history..."
    Seed::BillingDataService.create(company: @retail)
    puts "  -> Billing data generated (DailyMetricLog: #{DailyMetricLog.where(company: @retail).count}, " \
         "DailyFeatureLog: #{DailyFeatureLog.where(company: @retail).count}, " \
         "Invoices: #{BillingInvoice.where(company: @retail).count})"
  end
end

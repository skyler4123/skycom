class Seed::RetailService
  EMPLOYEE_COUNTS = {
    branch_manager: 1,
    cashier: 3,
    sales_associate: 5,
    stock_clerk: 2
  }.freeze

  CUSTOMER_COUNTS = { customer: 20 }.freeze
  RETAIL_ROLES = (EMPLOYEE_COUNTS.keys + CUSTOMER_COUNTS.keys).freeze
  COMPANY_GROUP_BUSINESS_TYPE = :retail

  def initialize(user:)
    @multi_company_group_owner = user
    @retail = nil
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []
    @services = []

    seeding
  end

  def seeding
    print_header

    create_retail_company_group
    create_branches
    subscribe_companies_to_system_subscription_plane
    create_subscription_plans_for_company_group
    create_facilities_for_branches
    appoint_payment_methods_to_company_group
    setup_roles_and_permissions
    create_departments_for_branches
    create_employees_and_assign_departments
    create_customers_for_company_group
    subscribe_for_customers
    # setup_loyalty_programs
    # create_inventory # Products and Services
    # create_customer_orders

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

  def create_retail_company_group
    puts "Creating retail group..."
    @retail = Seed::CompanyGroupService.create(
      user: @multi_company_group_owner,
      name: "Retail Group #{rand(1000..9999)}",
      description: "A group for multiple retail branch companies",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    count.times do |i|
      branch = Seed::CompanyService.create(
        name: "Branch #{i + 1}",
        description: "Description for Branch #{i + 1}",
        parent_company: nil,
        company_group: @retail
      )
      branch.attach_tag(name: "Branch #{branch.id} Tag")
      @branches << branch
    end
  end

  def subscribe_companies_to_system_subscription_plane
    @branches.each do |branch|
      plan_name = SystemSubscriptionPlan.pluck(:name).sample
      branch.system_subscribe!(plan_name: plan_name)
    end
  end

  def create_subscription_plans_for_company_group(count: 3)
    count.times do |i|
      price = Seed::PriceService.create(
        amount: rand(10..100),
        currency_code: @retail.currency_code
      )
      Seed::SubscriptionPlanService.create(
        company_group: @retail,
        name: "Plan #{i + 1}",
        price: price,
        duration_days: rand(30..365)
      )
    end
  end

  def create_subscriptions_for_company_group(count: 3)
    count.times do |i|
      Seed::SubscriptionService.create(
        company_group: @retail,
        name: "Retail Company Group Subscription #{i + 1}",
        description: "Subscription plan #{i + 1} for #{@retail.name}"
      )
    end
  end

  def subscribe_branches_to_plans
    @branches.each do |branch|
      branch.subscribe!(plan_name: Subscription.plan_names.keys.sample)
    end
    
  end

  def create_facilities_for_branches
    @branches.each do |branch|
      facility_count = rand(1..3)
      facility_count.times do |i|
        facility = Seed::FacilityService.create(
          company_group: @retail,
          company: branch,
          name: "#{branch.name} Facility #{i + 1}",
          description: "A facility location for #{branch.name}"
        )
        facility.attach_tag(name: "Facility #{facility.id} Tag")
        @facilities << facility
      end
    end
  end

  def appoint_payment_methods_to_company_group
    @branches.each do |branch|
      3.times { Seed::PaymentMethodAppointmentService.create(company_group: @retail) }
    end
  end

  def setup_roles_and_permissions
    RETAIL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company_group: @retail,
        name: role_name,
        description: "#{role_name} role for #{@retail.name}"
      )
    end
    configure_retail_permissions
  end

  def create_departments_for_branches
    @branches.each do |branch|
      [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each do |dept_name|
        department = Seed::EmployeeGroupService.create(
          company_group: @retail,
          company: branch,
          name: dept_name,
          description: "Department: #{dept_name} in #{branch.name}"
        )
        department.update!(category: Seed::CategoryService.create(company_group: @retail, name: "Department"))
        department.attach_tag(name: "Department #{department.id} Tag")
        @departments << department
      end
    end
  end

  def create_employees_and_assign_departments
    @branches.each do |branch|
      branch_employees = []
      
      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "#{role_name}_#{i + 1}_#{branch.id}@example.com")
          employee = Seed::EmployeeService.create(
            user: user, company_group: @retail, company: branch,
            name: "Employee #{i + 1} - #{role_name.to_s.titleize}"
          )
          employee.attach_role(role_name)
          branch_employees << employee
        end
      end
      
      @employees.concat(branch_employees)
      assign_employees_to_random_dept(branch, branch_employees)
    end
  end

  def assign_employees_to_random_dept(branch, employees)
    branch_depts = @departments.select { |d| d.company_id == branch.id }
    employees.each do |employee|
      Seed::EmployeeGroupAppointmentService.create(employee_group: branch_depts.sample, appoint_to: employee)
    end
  end

  def create_customers_for_company_group
    @branches.each do |branch|
      CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "customer_#{i + 1}_#{branch.id}@example.com")
          customer = Seed::CustomerService.create(
            user: user, company_group: @retail, company: branch, name: "Customer #{i + 1}"
          )
          customer.attach_role(role_name)
          @customers << customer
        end
      end
    end
  end

  def subscribe_for_customers
    @customers.each do |customer|
      Seed::SubscriptionService.create(
        subscription_plan: @retail.subscription_plans.sample,
        period: Seed::PeriodService.create,
        seller: @retail,
        buyer: customer
      )
    end 
  end

  def setup_loyalty_programs
    @branches.each do |branch|
      2.times do |i|
        lp = Seed::CustomerGroupService.create(
          company_group: @retail, company: branch, name: "Loyalty Program #{i + 1} - #{branch.name}"
        )
        @loyalty_programs << lp
        
        branch_customers = @customers.select { |c| c.company_id == branch.id }
        branch_customers.sample(10).each do |customer|
          Seed::CustomerGroupAppointmentService.create(customer_group: lp, appoint_to: customer)
        end
      end
    end
  end

  def create_inventory
    @branches.each do |branch|
      # Products
      15.times do |i|
        @products << Seed::ProductService.create(
          company_group: @retail, company: branch, name: "#{Faker::Commerce.product_name} #{i + 1}"
        )
      end
      # Services
      10.times do |i|
        @services << Seed::ServiceService.create(
          company_group: @retail, company: branch, name: "#{Faker::Company.buzzword} Service #{i + 1}"
        )
      end
    end
  end

  def create_customer_orders
    @branches.each do |branch|
      branch_customers = @customers.select { |c| c.company_id == branch.id }
      next if branch_customers.empty?

      5.times do |i|
        customer = branch_customers.sample
        order = Seed::OrderService.create(
          company_group: @retail, company: branch, customer: customer, name: "Order #{i + 1} for #{customer.name}"
        )
        attach_items_to_order(branch, order)
      end
    end
  end

  def attach_items_to_order(branch, order)
    # Attach Products
    branch_products = @products.select { |p| p.company_id == branch.id }
    branch_products.sample(rand(2..3)).each do |product|
      OrderAppointment.create!(order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(10.0..100.0).round(2), total_price: 0)
    end

    # Attach Services
    branch_services = @services.select { |s| s.company_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..200.0).round(2), total_price: 0)
    end
  end

  def configure_retail_permissions
    # Define capabilities for each role
    # Actions: create, read, update, delete

    role_definitions = {
      branch_manager: {
        "Order" => [ "create", "read", "update", "delete" ],
        "Product" => [ "create", "read", "update", "delete" ],
        "Employee" => [ "create", "read", "update", "delete" ],
        "Customer" => [ "create", "read", "update", "delete" ]
      },
      cashier: {
        "Order" => [ "create", "read", "update" ], # Can process sales, maybe returns
        "Product" => [ "read" ],                    # Needs to see prices
        "Customer" => [ "read", "create" ]          # Can lookup or add customers
      },
      sales_associate: {
        "Order" => [ "create", "read" ],            # Can help create quotes/orders
        "Product" => [ "read" ],
        "Customer" => [ "read" ]
      },
      stock_clerk: {
        "Product" => [ "create", "read", "update", "delete" ], # Full control of inventory
        "Order" => [] # No access to orders
      },
      customer: {
        "Order" => [ "read" ], # Can see their own orders (logic handled in policy scope usually)
        "Product" => [ "read" ]
      }
    }

    role_definitions.each do |role_name, resources|
      # 1. Find the Role object created in Step 4
      role = Role.find_by(name: role_name, company_group: @retail)
      next unless role

      resources.each do |resource_name, actions|
        actions.each do |action|
          # 2. Create the Policy (The Permission)
          # We check uniqueness by name/company_group to avoid duplicates if re-seeded
          policy_name = "Can #{action} #{resource_name}"

          # Using raw ActiveRecord here. If you have Seed::PolicyService, use that instead.
          policy = Policy.find_or_create_by!(
            name: policy_name,
            company_group: @retail,
            resource: resource_name,
            action: action
          ) do |p|
            p.description = "Allows #{action} operations on #{resource_name}"
            p.business_type = :operational
            p.lifecycle_status = :active
            # Company ID is required by your schema validation, picking the first branch as reference
            # or the group owner's context.
            p.company_id = @branches.first.id
          end

          # 3. Link Policy to Role via PolicyAppointment
          PolicyAppointment.find_or_create_by!(
            policy: policy,
            appoint_to: role
          )
        end
      end
    end
  end
end

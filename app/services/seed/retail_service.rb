class Seed::RetailService
  # Define the number of employees to create for each role in each branch
  EMPLOYEE_COUNTS = {
    branch_manager: 1,
    cashier: 3,
    sales_associate: 5,
    stock_clerk: 2
  }.freeze

  # Define the number of customers to create for each branch
  CUSTOMER_COUNTS = {
    customer: 20
  }.freeze

  # Define the standard roles to be created for the retail group
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
    puts "\n\n🛍️  Starting Retail Company Group Seeding..."
    puts "========================================================="

    # --- 1. Create Retail Company Group ---
    puts "Creating 1 retail company group..."
    @retail = Seed::CompanyGroupService.create(
      user: @multi_company_group_owner,
      name: "Retail Company Group #{rand(1000..9999)}",
      description: "A group for multiple retail branch companies",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
    puts "Created retail company group: #{@retail.name}"

    #--- 2. Create Branches (Companies) under the Company Group ---
    branch_count = 2
    puts "Creating #{branch_count} branches under the company group..."
    branch_count.times do |i|
      branch = Seed::CompanyService.create(
        name: "Branch #{i + 1}",
        description: "Description for Branch #{i + 1}",
        parent_company: nil,
        company_group: @retail
      )
      branch.attach_tag(name: "Branch #{branch.id} Tag")
      @branches << branch
    end
    puts "Created #{@branches.count} branches under the company group."

    # --- 2.5. [NEW] Subscribe the Company Group to a Subscription Tier ---
    @branches.map do |branch|
      branch.subscribe!(
        plan_name: Subscription.plan_names.keys.sample
      )
    end

    # --- 2.6. Create Facilities for Each Branch (Company) ---
    @branches.each do |branch|
      puts "Creating facilities for #{branch.name}..."
      facility_count = rand(1..3) # Each branch gets 1-3 facilities
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
      puts "Created #{facility_count} facilities for #{branch.name}."
    end

    #--- 3. Create Payment Method Appointments for Branches (Companies) ---
    @branches.each do |branch|
      3.times do
        Seed::PaymentMethodAppointmentService.create(
          company_group: @retail
        )
      end
    end
    puts "Appointed some payment methods to each branch."

    # --- 4. Create Retail Roles ---
    RETAIL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company_group: @retail,
        name: role_name,
        description: "#{role_name} role for #{@retail.name}"
      )
    end
    puts "Created #{RETAIL_ROLES.count} roles for the retail group."

    # --- 4.5. [NEW] Configure Permissions (Policies) for Roles ---
    # This setup ensures specific roles have CRUD access to specific resources
    configure_retail_permissions
    puts "configured policies/permissions for retail roles."


    # --- 5. Create Departments (Employee Groups) for Each Branch (Company) ---
    @branches.each do |branch|
      puts "Creating departments for #{branch.name}..."
      [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each do |dept_name|
        department = Seed::EmployeeGroupService.create(
          company_group: @retail,
          company: branch,
          name: dept_name,
          description: "Department: #{dept_name} in #{branch.name}"
        )
        department.update!(category: Seed::CategoryService.create(
          company_group: @retail,
          name: "Department"
        ))
        department.attach_tag(name: "Department #{department.id} Tag")
        @departments << department
      end
      puts "Created departments for #{branch.name}."
    end

    # --- 6. Create Employees for Each Branch (Company) ---
    @branches.each do |branch|
      puts "Creating employees for #{branch.name}..."
      current_employees = []
      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "#{role_name.downcase}_#{i + 1}_#{branch.id}@example.com")
          employee = Seed::EmployeeService.create(
            user: user,
            company_group: @retail,
            company: branch,
            name: "Employee #{i + 1} - #{role_name.to_s.titleize}",
            description: "Description for Employee #{i + 1} - #{role_name.to_s.titleize}"
          )
          employee.attach_tag(name: "Employee #{employee.id} Tag")

          # This attaches the Role record created in step 4
          # Because we ran step 4.5, this role now carries Policies (Permissions)
          employee.attach_role(role_name)

          current_employees << employee
        end
      end
      @employees.concat(current_employees)
      puts "Created #{current_employees.count} employees for #{branch.name}."

      # --- 7. Assign Employees to Departments ---
      branch_departments = @departments.select { |d| d.company_id == branch.id }
      current_employees.each do |employee|
        # Assign each employee to a random department in their branch
        department = branch_departments.sample
        Seed::EmployeeGroupAppointmentService.create(
          employee_group: department,
          appoint_to: employee
        )
      end
      puts "Assigned employees to departments for #{branch.name}."
    end

    # --- 8. Create Customers for Each Branch (Company) ---
    @branches.each do |branch|
      puts "Creating customers for #{branch.name}..."
      current_customers = []
      CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "customer_#{i + 1}_#{branch.id}@example.com")
          customer = Seed::CustomerService.create(
            user: user,
            company_group: @retail,
            company: branch,
            name: "Customer #{i + 1}",
            description: "A customer of #{branch.name}"
          )
          customer.attach_tag(name: "Customer #{customer.id} Tag")
          customer.attach_role(role_name)
          current_customers << customer
        end
      end
      @customers.concat(current_customers)
      puts "Created #{current_customers.count} customers for #{branch.name}."
    end

    # --- 9. Create Loyalty Programs (Customer Groups) and Enroll Customers ---
    @branches.each do |branch|
      puts "Creating loyalty programs and enrolling customers for #{branch.name}..."
      2.times do |i|
        loyalty_program = Seed::CustomerGroupService.create(
          company_group: @retail,
          company: branch,
          name: "Loyalty Program #{i + 1} - #{branch.name}",
          description: "Exclusive benefits for members."
        )
        loyalty_program.attach_tag(name: "Loyalty #{loyalty_program.id} Tag")
        @loyalty_programs << loyalty_program

        # Enroll 10 random customers from this branch
        branch_customers = @customers.select { |c| c.company_id == branch.id }
        enrolled_customers = branch_customers.sample(10)
        enrolled_customers.each do |customer|
          Seed::CustomerGroupAppointmentService.create(
            customer_group: loyalty_program,
            appoint_to: customer
          )
        end
      end
      puts "Created loyalty programs and enrolled customers for #{branch.name}."
    end

    # --- 10. Create some Products for Each Branch ---
    @branches.each do |branch|
      puts "Creating products for #{branch.name}..."
      15.times do |i|
        product = Seed::ProductService.create(
          company_group: @retail,
          company: branch,
          name: "#{Faker::Commerce.product_name} #{i + 1}",
          description: "A quality product from #{branch.name}"
        )
        product.attach_tag(name: "Product #{product.id} Tag")
        @products << product
      end
      puts "Created 15 products for #{branch.name}."
    end

    # --- 11. Create some Services for Each Branch ---
    @branches.each do |branch|
      puts "Creating services for #{branch.name}..."
      10.times do |i|
        service = Seed::ServiceService.create(
          company_group: @retail,
          company: branch,
          name: "#{Faker::Company.buzzword} Service #{i + 1}",
          description: "A professional service offered by #{branch.name}"
        )
        service.attach_tag(name: "Service #{service.id} Tag")
        @services << service
      end
      puts "Created 10 services for #{branch.name}."
    end

    # --- 12. Create Orders for Customers and Attach Products/Services ---
    puts "Creating orders for customers and attaching products/services..."
    @branches.each do |branch|
      # Create 5 orders per branch
      5.times do |i|
        # Pick a random customer from this branch
        branch_customers = @customers.select { |c| c.company_id == branch.id }
        customer = branch_customers.sample
        next unless customer # Skip if no customers

        # Create an order
        order = Seed::OrderService.create(
          company_group: @retail,
          company: branch,
          customer: customer,
          name: "Order #{i + 1} for #{customer.name}",
          description: "Retail order for #{customer.name} at #{branch.name}"
        )

        # Attach 2-3 products to the order
        branch_products = @products.select { |p| p.company_id == branch.id }
        products_to_attach = branch_products.sample(rand(2..3))
        products_to_attach.each do |product|
          OrderAppointment.create!(
            order: order,
            appoint_to: product,
            quantity: rand(1..5),
            unit_price: rand(10.0..100.0).round(2),
            total_price: 0, # Will be calculated if needed
            name: "Appointment of #{product.name} to Order #{order.name}",
            description: "Product appointment for order"
          )
        end

        # Attach 1-2 services to the order
        branch_services = @services.select { |s| s.company_id == branch.id }
        services_to_attach = branch_services.sample(rand(1..2))
        services_to_attach.each do |service|
          OrderAppointment.create!(
            order: order,
            appoint_to: service,
            quantity: 1,
            unit_price: rand(50.0..200.0).round(2),
            total_price: 0, # Will be calculated if needed
            name: "Appointment of #{service.name} to Order #{order.name}",
            description: "Service appointment for order"
          )
        end

        puts "Created order #{order.name} with #{products_to_attach.count} products and #{services_to_attach.count} services."
      end
    end
    puts "Created orders and attached products/services."

    puts "\n========================================================="
    puts "🛍️  Retail Company Group Seeding Complete!"
    puts "========================================================="
    true
  end

  private

  # --------------------------------------------------------------------------
  # PERMISSION LOGIC (RBAC)
  # --------------------------------------------------------------------------
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

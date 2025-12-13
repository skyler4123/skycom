class Seed::RetailService
  # Define the number of employees to create for each role in each store
  EMPLOYEE_COUNTS = {
    store_manager: 1,
    cashier: 3,
    sales_associate: 5,
    stock_clerk: 2
  }.freeze

  # Define the number of customers to create for each store
  CUSTOMER_COUNTS = {
    customer: 20
  }.freeze

  # Define the standard roles to be created for the retail group
  RETAIL_ROLES = (EMPLOYEE_COUNTS.keys + CUSTOMER_COUNTS.keys).freeze

  COMPANY_GROUP_BUSINESS_TYPE = :retail

  def initialize(user:)
    @multi_company_group_owner = user
    @retail_group = nil
    @stores = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []

    seeding
  end

  def seeding
    puts "\n\n🛍️  Starting Retail Company Group Seeding..."
    puts "========================================================="

    # --- 1. Create Retail Company Group ---
    puts "Creating 1 retail company group..."
    @retail_group = Seed::CompanyGroupService.create(
      user: @multi_company_group_owner,
      name: "Retail Company Group #{rand(1000..9999)}",
      description: "A group for multiple retail store companies",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
    puts "Created retail company group: #{@retail_group.name}"

    #--- 2. Create Stores (Companies) under the Company Group ---
    store_count = 2
    puts "Creating #{store_count} stores under the company group..."
    store_count.times do |i|
      store = Seed::CompanyService.create(
        name: "Store #{i + 1}",
        description: "Description for Store #{i + 1}",
        parent_company: nil,
        company_group: @retail_group
      )
      store.attach_tag(name: "Store #{store.id} Tag")
      @stores << store
    end
    puts "Created #{@stores.count} stores under the company group."

    #--- 3. Create Payment Method Appointments for Stores (Companies) ---
    @stores.each do |store|
      3.times do
        Seed::PaymentMethodAppointmentService.create(
          company_group: @retail_group
        )
      end
    end
    puts "Appointed some payment methods to each store."

    # --- 4. Create Retail Roles ---
    RETAIL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company_group: @retail_group,
        name: role_name,
        description: "#{role_name} role for #{@retail_group.name}"
      )
    end
    puts "Created #{RETAIL_ROLES.count} roles for the retail group."

    # --- 5. Create Departments (Employee Groups) for Each Store (Company) ---
    @stores.each do |store|
      puts "Creating departments for #{store.name}..."
      [ "Electronics", "Clothing", "Home Goods", "Customer Service" ].each do |dept_name|
        department = Seed::EmployeeGroupService.create(
          company_group: @retail_group,
          company: store,
          name: dept_name,
          description: "Department: #{dept_name} in #{store.name}"
        )
        department.attach_tag(name: "Department #{department.id} Tag")
        @departments << department
      end
      puts "Created departments for #{store.name}."
    end

    # --- 6. Create Employees for Each Store (Company) ---
    @stores.each do |store|
      puts "Creating employees for #{store.name}..."
      current_employees = []
      EMPLOYEE_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "#{role_name.downcase}_#{i + 1}_#{store.id}@example.com")
          employee = Seed::EmployeeService.create(
            user: user,
            company_group: @retail_group,
            company: store,
            name: "Employee #{i + 1} - #{role_name.to_s.titleize}",
            description: "Description for Employee #{i + 1} - #{role_name.to_s.titleize}"
          )
          employee.attach_tag(name: "Employee #{employee.id} Tag")
          employee.attach_role(role_name)
          current_employees << employee
        end
      end
      @employees.concat(current_employees)
      puts "Created #{current_employees.count} employees for #{store.name}."

      # --- 7. Assign Employees to Departments ---
      store_departments = @departments.select { |d| d.company_id == store.id }
      current_employees.each do |employee|
        # Assign each employee to a random department in their store
        department = store_departments.sample
        Seed::EmployeeGroupAppointmentService.create(
          employee_group: department,
          appoint_to: employee
        )
      end
      puts "Assigned employees to departments for #{store.name}."
    end

    # --- 8. Create Customers for Each Store (Company) ---
    @stores.each do |store|
      puts "Creating customers for #{store.name}..."
      current_customers = []
      CUSTOMER_COUNTS.each do |role_name, count|
        count.times do |i|
          user = Seed::UserService.create(parent_user: @multi_company_group_owner, email: "customer_#{i + 1}_#{store.id}@example.com")
          customer = Seed::CustomerService.create(
            user: user,
            company_group: @retail_group,
            company: store,
            name: "Customer #{i + 1}",
            description: "A customer of #{store.name}"
          )
          customer.attach_tag(name: "Customer #{customer.id} Tag")
          customer.attach_role(role_name)
          current_customers << customer
        end
      end
      @customers.concat(current_customers)
      puts "Created #{current_customers.count} customers for #{store.name}."
    end

    # --- 9. Create Loyalty Programs (Customer Groups) and Enroll Customers ---
    @stores.each do |store|
      puts "Creating loyalty programs and enrolling customers for #{store.name}..."
      2.times do |i|
        loyalty_program = Seed::CustomerGroupService.create(
          company_group: @retail_group,
          company: store,
          name: "Loyalty Program #{i + 1} - #{store.name}",
          description: "Exclusive benefits for members."
        )
        loyalty_program.attach_tag(name: "Loyalty #{loyalty_program.id} Tag")
        @loyalty_programs << loyalty_program

        # Enroll 10 random customers from this store
        store_customers = @customers.select { |c| c.company_id == store.id }
        enrolled_customers = store_customers.sample(10)
        enrolled_customers.each do |customer|
          Seed::CustomerGroupAppointmentService.create(
            customer_group: loyalty_program,
            appoint_to: customer
          )
        end
      end
      puts "Created loyalty programs and enrolled customers for #{store.name}."
    end

    # --- 10. Create some Products for Each Store ---
    @stores.each do |store|
      puts "Creating products for #{store.name}..."
      15.times do |i|
        product = Seed::ProductService.create(
          company_group: @retail_group,
          company: store,
          name: "#{Faker::Commerce.product_name} #{i + 1}",
          description: "A quality product from #{store.name}"
        )
        product.attach_tag(name: "Product #{product.id} Tag")
        @products << product
      end
      puts "Created 15 products for #{store.name}."
    end

    puts "\n========================================================="
    puts "🛍️  Retail Company Group Seeding Complete!"
    puts "========================================================="
    true
  end
end

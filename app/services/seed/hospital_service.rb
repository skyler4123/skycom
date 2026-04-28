class Seed::HospitalService
  EMPLOYEE_COUNTS = {
    Manager: 1,
    Doctor: 5,
    Nurse: 10,
    Receptionist: 3,
    Admin: 2
  }.freeze

  CUSTOMER_COUNTS = { Patient: 20 }.freeze
  HOSPITAL_ROLES = (EMPLOYEE_COUNTS.keys + CUSTOMER_COUNTS.keys).freeze
  COMPANY_GROUP_BUSINESS_TYPE = :hospital

  def initialize(user:, email: Faker::Internet.email)
    @multi_company_owner = user
    @hospital = nil
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @customers = []
    @loyalty_programs = []
    @products = []
    @services = []
    @email = email
    @email_domain = EmailService.new(email).full_domain
    seeding
  end

  def seeding
    print_header

    create_hospital_company
    create_branches
    subscribe_branches_to_system_subscription_plane
    create_subscription_plans_for_company
    create_facilities_for_branches
    appoint_payment_methods_to_company
    setup_roles_and_permissions
    create_departments_for_company
    create_employees
    assign_employees_to_departments
    create_customers_for_company
    subscribe_for_customers
    setup_loyalty_programs
    create_inventory
    create_customer_orders

    print_footer
    true
  end

  private

  def print_header
    puts "\n\n🏥  Starting Hospital Company Group Seeding..."
    puts "========================================================="
  end

  def print_footer
    puts "\n========================================================="
    puts "🏥  Hospital Company Group Seeding Complete!"
    puts "========================================================="
  end

  def create_hospital_company
    puts "Creating hospital group..."
    @hospital = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: "Hospital #{Company.count + 1}",
      email: @email,
      description: "A group for multiple hospital branch locations",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Hospital Branch #{i + 1}",
        description: "Description for Hospital Branch #{i + 1}",
        company: @hospital
      )
      branch.attach_tag(key: "Branch #{branch.id} Tag")
      @branches << branch
    end
  end

  def subscribe_branches_to_system_subscription_plane
    @branches.each do |branch|
      plan_name = SystemSubscriptionPlan.pluck(:name).sample
      branch.system_subscribe!(plan_name: plan_name)
    end
  end

  def create_subscription_plans_for_company(count: 3)
    count.times do |i|
      price = Seed::PriceService.create(
        amount: rand(10..100),
        currency_code: @hospital.currency_code
      )
      Seed::SubscriptionPlanService.create(
        company: @hospital,
        name: "Plan #{i + 1}",
        price: price,
        duration_days: rand(30..365)
      )
    end
  end

  def create_subscriptions_for_company(count: 3)
    count.times do |i|
      Seed::SubscriptionService.create(
        company: @hospital,
        name: "Hospital Company Group Subscription #{i + 1}",
        description: "Subscription plan #{i + 1} for #{@hospital.name}"
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
          company: @hospital,
          branch: branch,
          name: "#{branch.name} Facility #{i + 1}",
          description: "A facility location for #{branch.name}"
        )
        facility.attach_tag(key: "Facility #{facility.id} Tag")
        @facilities << facility
      end
    end
  end

  def appoint_payment_methods_to_company
    @branches.each do |branch|
      3.times { Seed::PaymentMethodAppointmentService.create(company: @hospital) }
    end
  end

  def setup_roles_and_permissions
    HOSPITAL_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @hospital,
        name: role_name,
        description: "#{role_name} role for #{@hospital.name}"
      )
    end
    configure_hospital_permissions
  end

  def create_departments_for_company
    [ "Emergency", "Surgery", "Pediatrics", "Cardiology" ].each do |dept_name|
      department = Seed::DepartmentService.create(
        company: @hospital,
        name: dept_name,
        description: "Department: #{dept_name}"
      )
      department.update!(category: Seed::CategoryService.create(company: @hospital, name: "Department"))
      department.attach_tag(key: "Department #{department.id} Tag")
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
            email: "#{role_name}_#{i + 1}_hospital_branch_#{index + 1}@#{@email_domain}",
            system_role: :company_employee
          )
          employee = Seed::EmployeeService.create(
            user: user, company: @hospital, branch: branch,
            name: "Employee #{SecureRandom.hex(4)}"
          )
          employee.attach_role(role_name)
          branch_employees << employee
        end
      end

      @employees.concat(branch_employees)
    end
  end

  def assign_employees_to_departments
    @employees.each do |employee|
      Seed::DepartmentAppointmentService.create(
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
            email: "hospital_patient_#{i + 1}_#{branch.id}@example.com",
            system_role: :company_customer
          )
          customer = Seed::CustomerService.create(
            user: user, company: @hospital, branch: branch, name: "Patient #{SecureRandom.hex(4)}"
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
        company: @hospital,
        subscription_plan: @hospital.subscription_plans.sample,
        period: Seed::PeriodService.create,
        seller: @hospital,
        buyer: customer
      )
    end
  end

  def setup_loyalty_programs
    @branches.each do |branch|
      2.times do |i|
        lp = Seed::CustomerGroupService.create(
          company: @hospital, branch: branch, name: "Health Program #{i + 1} - #{branch.name}"
        )
        @loyalty_programs << lp

        branch_customers = @customers.select { |c| c.branch_id == branch.id }
        branch_customers.sample(10).each do |customer|
          Seed::CustomerGroupAppointmentService.create(customer_group: lp, appoint_to: customer)
        end
      end
    end
  end

  def create_inventory
    @branches.each do |branch|
      medical_supplies = [
        "Surgical Gloves", "Face Masks", "Bandages", "Syringes",
        "Medical Cotton", "Antiseptic Solution", "IV Sets", "Catheters",
        "Surgical Sutures", "Medical Tape", "Stethoscopes", "Thermometers",
        "Blood Pressure Monitor", "Pulse Oximeter", "First Aid Kit"
      ]

      medical_supplies.each do |item_name|
        @products << Seed::ProductService.create(
          company: @hospital,
          branch: branch,
          name: "#{item_name} - #{branch.name}"
        )
      end

      services = [
        "General Consultation", "Emergency Care", "Surgery", "Lab Tests", "MRI Scan"
      ]

      services.each do |service_name|
        @services << Seed::ServiceService.create(
          company: @hospital,
          branch: branch,
          name: "#{service_name} - #{branch.name}"
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
          company: @hospital, branch: branch, customer: customer, name: "Order #{i + 1} for #{customer.name}"
        )
        attach_items_to_order(branch, order)
      end
    end
  end

  def attach_items_to_order(branch, order)
    branch_products = @products.select { |p| p.branch_id == branch.id }
    branch_products.sample(rand(2..4)).each do |product|
      OrderAppointment.create!(order: order, appoint_to: product, quantity: rand(1..5), unit_price: rand(5.0..50.0).round(2), total_price: 0)
    end

    branch_services = @services.select { |s| s.branch_id == branch.id }
    branch_services.sample(rand(1..2)).each do |service|
      OrderAppointment.create!(order: order, appoint_to: service, quantity: 1, unit_price: rand(50.0..500.0).round(2), total_price: 0)
    end
  end

  def configure_hospital_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  def create_all_crud_policies
    resources = %w[Order Product Employee Customer PolicyAppointment]
    crud_actions = %w[create read update delete]

    resources.each do |resource|
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
      company: @hospital,
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
      Manager: {
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: true, read: true, update: true, delete: true }
      },
      Doctor: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: true, delete: false },
        "Employee" => { create: false, read: true, update: false, delete: false },
        "Customer" => { create: true, read: true, update: true, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Nurse: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: true, delete: false },
        "Employee" => { create: false, read: false, update: false, delete: false },
        "Customer" => { create: true, read: true, update: true, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Receptionist: {
        "Order" => { create: true, read: true, update: false, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Employee" => { create: false, read: false, update: false, delete: false },
        "Customer" => { create: true, read: true, update: true, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Admin: {
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: true, read: true, update: true, delete: true },
        "Customer" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: true, read: true, update: true, delete: true }
      }
    }

    role_definitions.each do |role_name, resources|
      role = Role.find_by(name: role_name, company: @hospital)
      next unless role

      resources.each do |resource_name, actions_hash|
        actions_hash.each do |action, is_active|
          policy = Policy.find_by!(company: @hospital, resource: resource_name, action: action)
          appointment = PolicyAppointment.find_or_create_by!(
            company: @hospital,
            policy: policy,
            appoint_to: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end
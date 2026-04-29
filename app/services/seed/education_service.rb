class Seed::EducationService
  EMPLOYEE_COUNTS = {
    Manager: 1,
    Professor: 5,
    Teacher: 10,
    Registrar: 3,
    Admin: 2,
    Student: 20
  }.freeze

  EDUCATION_ROLES = EMPLOYEE_COUNTS.keys.freeze
  COMPANY_GROUP_BUSINESS_TYPE = :education

  def initialize(user:, email: Faker::Internet.email)
    @multi_company_owner = user
    @education = nil
    @branches = []
    @facilities = []
    @departments = []
    @employees = []
    @email = email
    @email_domain = EmailService.new(email).full_domain
    seeding
  end

  def seeding
    print_header

    create_education_company
    create_branches
    subscribe_branches_to_system_subscription_plane
    create_subscription_plans_for_company
    create_facilities_for_branches
    appoint_payment_methods_to_company
    setup_roles_and_permissions
    create_departments_for_company
    create_employees
    assign_employees_to_departments
    create_inventory

    print_footer
    true
  end

  private

  def print_header
    puts "\n\n📚  Starting Education Company Group Seeding..."
    puts "========================================================="
  end

  def print_footer
    puts "\n========================================================="
    puts "📚  Education Company Group Seeding Complete!"
    puts "========================================================="
  end

  def create_education_company
    puts "Creating education group..."
    @education = Seed::CompanyService.create(
      user: @multi_company_owner,
      name: "Education #{Company.count + 1}",
      email: @email,
      description: "A group for multiple education branch locations",
      business_type: COMPANY_GROUP_BUSINESS_TYPE
    )
  end

  def create_branches(count: 2)
    puts "Creating #{count} branches..."
    count.times do |i|
      branch = Seed::BranchService.create(
        name: "Education Branch #{i + 1}",
        description: "Description for Education Branch #{i + 1}",
        company: @education
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
        currency_code: @education.currency_code
      )
      Seed::SubscriptionPlanService.create(
        company: @education,
        name: "Plan #{i + 1}",
        price: price,
        duration_days: rand(30..365)
      )
    end
  end

  def create_facilities_for_branches
    @branches.each do |branch|
      facility_count = rand(1..3)
      facility_count.times do |i|
        facility = Seed::FacilityService.create(
          company: @education,
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
      3.times { Seed::PaymentMethodAppointmentService.create(company: @education) }
    end
  end

  def setup_roles_and_permissions
    EDUCATION_ROLES.each do |role_name|
      Seed::RoleService.create(
        company: @education,
        name: role_name,
        description: "#{role_name} role for #{@education.name}"
      )
    end
    configure_education_permissions
  end

  def create_departments_for_company
    [ "Science", "Arts", "Engineering", "Administration" ].each do |dept_name|
      department = Seed::DepartmentService.create(
        company: @education,
        name: dept_name,
        description: "Department: #{dept_name}"
      )
      department.update!(category: Seed::CategoryService.create(company: @education, name: "Department"))
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
            email: "#{role_name}_#{i + 1}_education_branch_#{index + 1}@#{@email_domain}",
            system_role: :company_employee
          )
          employee = Seed::EmployeeService.create(
            user: user, company: @education, branch: branch,
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

  def create_inventory
    @branches.each do |branch|
      school_supplies = [
        "Textbooks", "Lab Equipment", "Notebooks", "Pencils", "Pens",
        "Rulers", "Calculators", "Scientific Calculators", "Whiteboard Markers",
        "Erasers", "Folders", "Binders", "Paper Reams", "Art Supplies", "Sports Equipment"
      ]

      school_supplies.each do |item_name|
        Seed::ProductService.create(
          company: @education,
          branch: branch,
          name: "#{item_name} - #{branch.name}"
        )
      end

      services = [
        "Class Enrollment", "Tutoring", "Lab Access", "Library Access", "Extracurricular Activities"
      ]

      services.each do |service_name|
        Seed::ServiceService.create(
          company: @education,
          branch: branch,
          name: "#{service_name} - #{branch.name}"
        )
      end
    end
  end

  def configure_education_permissions
    create_all_crud_policies
    assign_policies_to_roles
  end

  def create_all_crud_policies
    resources = %w[Order Product Employee PolicyAppointment]
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
      company: @education,
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
        "PolicyAppointment" => { create: true, read: true, update: true, delete: true }
      },
      Professor: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: true, delete: false },
        "Employee" => { create: false, read: true, update: false, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Teacher: {
        "Order" => { create: true, read: true, update: true, delete: false },
        "Product" => { create: false, read: true, update: true, delete: false },
        "Employee" => { create: false, read: false, update: false, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Registrar: {
        "Order" => { create: true, read: true, update: false, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Employee" => { create: false, read: false, update: false, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      },
      Admin: {
        "Order" => { create: true, read: true, update: true, delete: true },
        "Product" => { create: true, read: true, update: true, delete: true },
        "Employee" => { create: true, read: true, update: true, delete: true },
        "PolicyAppointment" => { create: true, read: true, update: true, delete: true }
      },
      Student: {
        "Order" => { create: false, read: false, update: false, delete: false },
        "Product" => { create: false, read: true, update: false, delete: false },
        "Employee" => { create: false, read: false, update: false, delete: false },
        "PolicyAppointment" => { create: false, read: false, update: false, delete: false }
      }
    }

    role_definitions.each do |role_name, resources|
      role = Role.find_by(name: role_name, company: @education)
      next unless role

      resources.each do |resource_name, actions_hash|
        actions_hash.each do |action, is_active|
          policy = Policy.find_by!(company: @education, resource: resource_name, action: action)
          appointment = PolicyAppointment.find_or_create_by!(
            company: @education,
            policy: policy,
            appoint_to: role
          )
          appointment.update!(workflow_status: is_active ? :active : :inactive)
        end
      end
    end
  end
end

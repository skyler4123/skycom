# spec/factories/employees.rb
FactoryBot.define do
  factory :employee do
    association :company

    user { association :user }
    branch { association :branch, company: company }

    transient do
      departments { [] }
      roles { [] }
      employee_business_type { nil }
    end

    initialize_with do
      Seed::EmployeeService.new(
        company: company,
        branch: branch,
        user: user,
        departments: departments,
        roles: roles,
        business_type: employee_business_type
      )
    end
  end
end

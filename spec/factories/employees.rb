# spec/factories/employees.rb
FactoryBot.define do
  factory :employee do
    association :company

    # Optional: Default to a user and branch from the same company
    user { association :user }
    branch { association :branch, company: company }

    # Arrays for HABTM or HasManyThrough associations
    transient do
      departments_count { 0 }
      roles_count { 0 }
    end

    initialize_with do
      Seed::EmployeeService.create(
        company: company,
        branch: branch,
        user: user,
        departments: departments,
        roles: roles,
        business_type: business_type
      )
    end

    skip_create
  end
end

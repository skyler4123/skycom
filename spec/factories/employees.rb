# spec/factories/employees.rb
FactoryBot.define do
  factory :employee do
    association :company

    user { association :user }

    branch { association :branch, company: company }

    transient do
      employee_business_type { [ :full_time, :part_time, :contractor, :intern ].sample }
    end

    initialize_with do
      Seed::EmployeeService.new(
        company: company,
        branch: branch,
        user: user,
        business_type: employee_business_type
      )
    end
  end
end

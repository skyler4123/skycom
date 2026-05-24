# spec/factories/employees.rb
FactoryBot.define do
  factory :employee do
    association :company
    user { association :user }
    branch { association :branch, company: company }

    initialize_with do
      Seed::EmployeeService.new(
        company: company,
        branch: branch,
        user: user
      )
    end
  end
end

# spec/factories/employee_groups.rb
FactoryBot.define do
  factory :employee_group do
    association :company

    initialize_with do
      Seed::EmployeeGroupService.new(company: company)
    end
  end
end

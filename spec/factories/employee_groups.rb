# spec/factories/employee_groups.rb
FactoryBot.define do
  factory :employee_group do
    association :company

    initialize_with do
      Seed::EmployeeGroupService.create(company: company)
    end

    skip_create
  end
end

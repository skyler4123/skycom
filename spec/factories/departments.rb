# spec/factories/departments.rb
FactoryBot.define do
  factory :department do
    association :company

    initialize_with do
      Seed::DepartmentService.create(company: company)
    end

    skip_create
  end
end

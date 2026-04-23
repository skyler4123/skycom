# spec/factories/departments.rb
FactoryBot.define do
  factory :department do
    association :company

    initialize_with do
      Seed::DepartmentService.new(company: company)
    end

  end
end

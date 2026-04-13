# spec/factories/branches.rb
FactoryBot.define do
  factory :branch do
    association :company # Automatically triggers Seed::CompanyService

    initialize_with do
      Seed::BranchService.create(company: company)
    end

    skip_create
  end
end
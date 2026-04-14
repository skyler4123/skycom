# spec/factories/services.rb
FactoryBot.define do
  factory :service do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ServiceService.create(company: company, branch: branch)
    end

    skip_create
  end
end

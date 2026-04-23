# spec/factories/services.rb
FactoryBot.define do
  factory :service do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ServiceService.new(company: company, branch: branch)
    end
  end
end

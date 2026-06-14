# spec/factories/pages.rb
FactoryBot.define do
  factory :page do
    association :company
    branch { association :branch, company: company }
    target_role { :retail_cashier }

    initialize_with do
      Seed::PageService.new(
        company: company,
        branch: branch,
        target_role: target_role
      )
    end
  end
end

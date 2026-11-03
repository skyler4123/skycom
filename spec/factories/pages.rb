# spec/factories/pages.rb
FactoryBot.define do
  factory :page do
    association :company
    branch { association :branch, company: company }
    target_role { :retail_cashier }
    target_resolution { :desktop }
    name { nil }
    business_type { nil }
    metadata { {} }

    initialize_with do
      Seed::PageService.new(
        company: company,
        branch: branch,
        name: name,
        business_type: business_type,
        target_role: target_role,
        target_resolution: target_resolution,
        metadata: metadata || {}
      )
    end
  end
end

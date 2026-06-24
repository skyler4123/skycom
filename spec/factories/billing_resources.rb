# frozen_string_literal: true

FactoryBot.define do
  factory :billing_resource do
    name { "test_resource" }
    description { "Test billing resource" }
    resource_type { :volumetric }

    trait :addon_feature do
      resource_type { :addon_feature }
    end

    trait :volumetric do
      resource_type { :volumetric }
    end
  end
end

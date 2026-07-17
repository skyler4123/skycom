# frozen_string_literal: true

FactoryBot.define do
  factory :billing_resource do
    name { "test_resource" }
    description { "Test billing resource" }
    resource_type { :volumetric }
    country { :us }

    trait :addon_feature do
      resource_type { :addon_feature }
    end

    trait :volumetric do
      resource_type { :volumetric }
    end

    trait :vn do
      country { :vn }
    end
  end
end

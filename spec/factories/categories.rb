# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    association :company

    initialize_with do
      Seed::CategoryService.new(company: company)
    end

    after(:create) do |category|
      next unless category.property_mapping

      all_properties = Seed::CategoryService.random_property_labels
      category.property_mapping.update!(**all_properties) if all_properties.present?
    end
  end
end

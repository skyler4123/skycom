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
      metadatas = Seed::CategoryService.build_property_metadatas(all_properties)
      category.property_mapping.update!(property_metadatas: metadatas) if metadatas.present?
    end
  end
end

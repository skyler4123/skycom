# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    association :company

    initialize_with do
      Seed::CategoryService.new(company: company)
    end

    after(:create) do |category|
      next unless category.default_property_mapping

      all_properties = Seed::CategoryService.random_property_labels
      # Deterministic fixture convention: the table_config factory fixes
      # property_string_1 as "Skin Type" — guarantee the PM matches so the
      # column name-match validation never flakes.
      all_properties["property_string_1"] = "Skin Type"
      metadatas = Seed::CategoryService.build_property_metadata(all_properties)
      category.default_property_mapping.update!(metadata: { "properties" => metadatas }) if metadatas.present?
    end
  end
end

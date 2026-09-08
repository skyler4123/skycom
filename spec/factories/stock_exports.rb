# spec/factories/stock_exports.rb
FactoryBot.define do
  factory :stock_export do
    association :company
    association :product

    initialize_with do
      Seed::StockExportService.new(
        company: company,
        product: product,
        branch: nil
      ).tap do |record|
        if record.category.nil? && record.company.present?
          record.category = Seed::CategoryService.find_or_create_for(
            company: record.company,
            resource_name: record.class.model_name.plural
          )
        end
        if record.property_mapping.nil? && record.category.present?
          record.property_mapping = record.category.default_property_mapping
        end
      end
    end
  end
end

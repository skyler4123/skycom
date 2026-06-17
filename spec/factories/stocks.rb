# spec/factories/stocks.rb
FactoryBot.define do
  factory :stock do
    association :warehouse
    association :product

    initialize_with do
      Seed::StockService.new(
        warehouse: warehouse,
        product_id: product.id,
        company: warehouse.company,
        branch: warehouse.branch
      ).tap do |record|
        if record.category.nil? && record.company.present?
          record.category = Seed::CategoryService.find_or_create_for(
            company: record.company,
            resource_name: record.class.model_name.plural
          )
        end
        if record.property_mapping.nil? && record.category.present?
          record.property_mapping = record.category.property_mapping
        end
      end
    end
  end
end

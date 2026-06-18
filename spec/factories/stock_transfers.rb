# spec/factories/stock_transfers.rb
FactoryBot.define do
  factory :stock_transfer do
    association :company
    association :product

    initialize_with do
      Seed::StockTransferService.new(
        company: company,
        product: product,
        branch: nil,
        appoint_from: nil,
        appoint_to: nil
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

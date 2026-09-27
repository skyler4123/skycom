FactoryBot.define do
  factory :stock_adjustment do
    association :company
    association :warehouse
    direction { :increase }
    sequence(:code) { |n| "STKAD-TEST-#{n}-#{SecureRandom.hex(2).upcase}" }
    name { "Stock take" }
    reason { "Cycle count" }
    workflow_status { :pending }

    initialize_with do
      StockAdjustment.new(
        company: company,
        warehouse: warehouse,
        category: category,
        property_mapping: property_mapping,
        code: code,
        name: name,
        direction: direction,
        reason: reason,
        workflow_status: workflow_status
      )
    end

    transient do
      category { nil }
      property_mapping { nil }
    end

    after(:build) do |record, evaluator|
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

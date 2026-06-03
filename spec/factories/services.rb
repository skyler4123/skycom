# spec/factories/services.rb
FactoryBot.define do
  factory :service do
    association :company
    association :branch, company: company

    initialize_with do
      Seed::ServiceService.new(company: company, branch: branch).tap do |record|
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

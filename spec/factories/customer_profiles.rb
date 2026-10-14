# spec/factories/customer_profiles.rb
FactoryBot.define do
  factory :customer_profile do
    association :company
    customer { association :customer, company: company }

    initialize_with do
      Seed::CustomerProfileService.new(company: company, customer: customer).tap do |record|
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

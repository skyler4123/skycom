# spec/factories/customer_subprofiles.rb
FactoryBot.define do
  factory :customer_subprofile do
    association :company
    customer { association :customer, company: company }
    customer_profile { association :customer_profile, company: company, customer: customer }

    initialize_with do
      Seed::CustomerSubprofileService.new(company: company, customer: customer, customer_profile: customer_profile).tap do |record|
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

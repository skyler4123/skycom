# spec/factories/facilities.rb
FactoryBot.define do
  factory :facility do
    association :company

    initialize_with do
      Seed::FacilityService.new(company: company).tap do |record|
        if record.category.nil? && record.company.present?
          record.category = Seed::CategoryService.find_or_create_for(
            company: record.company,
            resource_name: record.class.model_name.plural
          )
        end
      end
    end
  end
end

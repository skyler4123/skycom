# spec/factories/employee_profiles.rb
FactoryBot.define do
  factory :employee_profile do
    association :company
    employee { association :employee, company: company }

    initialize_with do
      Seed::EmployeeProfileService.new(company: company, employee: employee).tap do |record|
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

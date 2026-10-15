# spec/factories/employee_subprofiles.rb
FactoryBot.define do
  factory :employee_subprofile do
    association :company
    employee { association :employee, company: company }
    employee_profile { association :employee_profile, company: company, employee: employee }

    initialize_with do
      Seed::EmployeeSubprofileService.new(company: company, employee: employee, employee_profile: employee_profile).tap do |record|
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

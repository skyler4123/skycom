# spec/factories/employee_groups.rb
FactoryBot.define do
  factory :employee_group do
    association :company

    initialize_with do
      Seed::EmployeeGroupService.new(company: company).tap do |record|
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

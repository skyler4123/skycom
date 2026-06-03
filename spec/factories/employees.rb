# spec/factories/employees.rb
FactoryBot.define do
  factory :employee do
    association :company
    user { association :user }
    branch { association :branch, company: company }

    initialize_with do
      Seed::EmployeeService.new(
        company: company,
        branch: branch,
        user: user
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

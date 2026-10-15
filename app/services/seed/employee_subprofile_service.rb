class Seed::EmployeeSubprofileService
  def self.new(
    company:,
    employee:,
    employee_profile:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: "Subprofile #{SecureRandom.hex(4)}",
    description: Faker::Lorem.sentence(word_count: 10),
    code: "ES-#{SecureRandom.hex(4).upcase}",
    lifecycle_status: EmployeeSubprofile.lifecycle_statuses.keys.sample,
    workflow_status: EmployeeSubprofile.workflow_statuses.keys.sample,
    business_type: EmployeeSubprofile.business_types.keys.sample,
    discarded_at: nil,
    **extra
  )
    EmployeeSubprofile.new(
      company: company,
      branch: branch || employee&.branch,
      employee: employee,
      employee_profile: employee_profile,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at,
      **extra.slice(*EmployeeSubprofile.column_names.map(&:to_sym))
    )
  end

  def self.create(**kwargs)
    property_keys = EmployeeSubprofile.column_names.select { |c| c.start_with?("property_") }.map(&:to_sym)
    explicit = kwargs.slice(*property_keys).compact
    sub = new(**kwargs)
    if sub.category.nil? && sub.company.present?
      sub.category = Seed::CategoryService.random_for(
        company: sub.company,
        resource_name: EmployeeSubprofile.model_name.plural
      ) || Seed::CategoryService.find_or_create_for(
        company: sub.company,
        resource_name: EmployeeSubprofile.model_name.plural
      )
    end
    if sub.property_mapping.nil? && sub.category.present?
      sub.property_mapping = sub.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(sub)
    explicit.each { |k, v| sub[k] = v }
    sub.save!
    sub
  end
end

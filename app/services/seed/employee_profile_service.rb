class Seed::EmployeeProfileService
  def self.new(
    company:,
    employee:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: "Profile #{SecureRandom.hex(4)}",
    description: Faker::Lorem.sentence(word_count: 10),
    code: "EP-#{SecureRandom.hex(4).upcase}",
    lifecycle_status: EmployeeProfile.lifecycle_statuses.keys.sample,
    workflow_status: EmployeeProfile.workflow_statuses.keys.sample,
    business_type: EmployeeProfile.business_types.keys.sample,
    discarded_at: nil,
    **extra
  )
    EmployeeProfile.new(
      company: company,
      branch: branch || employee&.branch,
      employee: employee,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at,
      **extra.slice(*EmployeeProfile.column_names.map(&:to_sym))
    )
  end

  def self.create(**kwargs)
    property_keys = EmployeeProfile.column_names.select { |c| c.start_with?("property_") }.map(&:to_sym)
    explicit = kwargs.slice(*property_keys).compact
    profile = new(**kwargs)
    if profile.category.nil? && profile.company.present?
      profile.category = Seed::CategoryService.random_for(
        company: profile.company,
        resource_name: EmployeeProfile.model_name.plural
      ) || Seed::CategoryService.find_or_create_for(
        company: profile.company,
        resource_name: EmployeeProfile.model_name.plural
      )
    end
    if profile.property_mapping.nil? && profile.category.present?
      profile.property_mapping = profile.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(profile)
    explicit.each { |k, v| profile[k] = v }
    profile.save!
    profile
  end
end

class Seed::CustomerProfileService
  def self.new(
    company:,
    customer:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: "Profile #{SecureRandom.hex(4)}",
    description: Faker::Lorem.sentence(word_count: 10),
    code: "CP-#{SecureRandom.hex(4).upcase}",
    lifecycle_status: CustomerProfile.lifecycle_statuses.keys.sample,
    workflow_status: CustomerProfile.workflow_statuses.keys.sample,
    business_type: CustomerProfile.business_types.keys.sample,
    discarded_at: nil,
    **extra
  )
    CustomerProfile.new(
      company: company,
      branch: branch || customer&.branch,
      customer: customer,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      code: code,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at,
      **extra.slice(*CustomerProfile.column_names.map(&:to_sym))
    )
  end

  def self.create(**kwargs)
    property_keys = CustomerProfile.column_names.select { |c| c.start_with?("property_") }.map(&:to_sym)
    explicit = kwargs.slice(*property_keys).compact
    profile = new(**kwargs)
    if profile.category.nil? && profile.company.present?
      profile.category = Seed::CategoryService.random_for(
        company: profile.company,
        resource_name: CustomerProfile.model_name.plural
      ) || Seed::CategoryService.find_or_create_for(
        company: profile.company,
        resource_name: CustomerProfile.model_name.plural
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

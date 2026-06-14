class Seed::BranchService
  def self.new(
    company:,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    phone_number: nil,
    email: nil,
    currency_code: nil,
    country_code: nil,
    timezone: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    branch_type = business_type || Branch.business_types.keys.sample
    workflow_status ||= Branch.workflow_statuses.keys.sample
    lifecycle_status ||= Branch.lifecycle_statuses.keys.sample

    currency_code ||= company.currency_code
    country_code ||= company.country_code
    timezone ||= company.timezone
    name ||= "#{Faker::Company.name} #{branch_type}"
    description ||= Faker::Lorem.sentence(word_count: 10)
    phone_number ||= Faker::PhoneNumber.phone_number
    email ||= Faker::Internet.email

    code ||= "BR-#{company.id}-#{SecureRandom.hex(3).upcase}"

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Branch.new(
      company: company,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      code: code,
      phone_number: phone_number,
      email: email,
      currency_code: currency_code,
      country_code: country_code,
      timezone: timezone,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type || branch_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    branch = new(...)
    if branch.category.nil? && branch.company.present?
      branch.category = Seed::CategoryService.random_for(
        company: branch.company,
        resource_name: Branch.model_name.plural
      )
    end
    if branch.property_mapping.nil? && branch.category.present?
      branch.property_mapping = branch.category.property_mapping
    end
    Seed::PropertyPopulator.populate(branch)
    branch.save!
    Seed::AttachmentService.attach(record: branch, relation: :image_attachments, number: 2)
    branch
  end
end

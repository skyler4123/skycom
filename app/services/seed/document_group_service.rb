class Seed::DocumentGroupService
  def self.create(
    company:,
    branch: nil,
    name: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    DocumentGroup.create!(
      company: company,
      branch: branch,
      name: name || Faker::File.extension.capitalize,
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "DG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || DocumentGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || DocumentGroup.workflow_statuses.keys.sample,
      business_type: business_type || DocumentGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end

class Seed::ArticleGroupService
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
    ArticleGroup.create!(
      company: company,
      branch: branch,
      name: name || "Article Group #{Faker::Lorem.sentence(word_count: 2)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "AG-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || ArticleGroup.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || ArticleGroup.workflow_statuses.keys.sample,
      business_type: business_type || ArticleGroup.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end

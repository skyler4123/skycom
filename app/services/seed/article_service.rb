class Seed::ArticleService
  def self.create(
    company:,
    branch: nil,
    article_group: nil,
    title: nil,
    content: nil,
    description: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    article_group ||= ArticleGroup.create!(company: company, branch: branch) if company
    branch ||= article_group.branch if article_group
    company ||= article_group.company if article_group

    Article.create!(
      company: company,
      branch: branch,
      article_group: article_group,
      title: title || Faker::Lorem.sentence(word_count: 4),
      content: content || Faker::Lorem.paragraph(sentence_count: 5),
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "ART-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || Article.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Article.workflow_statuses.keys.sample,
      business_type: business_type || Article.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end

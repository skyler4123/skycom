class Seed::DocumentService
  def self.create(
    company:,
    branch: nil,
    document_group: nil,
    name: nil,
    description: nil,
    content: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    document_group ||= DocumentGroup.create!(company: company, branch: branch) if company
    branch ||= document_group.branch if document_group
    company ||= document_group.company if document_group

    Document.create!(
      company: company,
      branch: branch,
      document_group: document_group,
      name: name || "Document #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      content: content || Faker::Lorem.paragraph(sentence_count: 3),
      code: code || "DOC-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || Document.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Document.workflow_statuses.keys.sample,
      business_type: business_type || Document.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end

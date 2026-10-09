class Seed::DocumentService
  # Rich GFM samples (headings, tables, code, strikethrough, task lists, links)
  # used by enrich services so seeded docs showcase the marked renderer.
  # Seed/fixture data stays local per docs/CONSTANTS.md.
  RICH_BODY_MARKDOWN_VARIANTS = [
    "# Leave Policy\n\nTake **days** off with *pay*.\n\n| Type | Days |\n| --- | --- |\n| Annual | 12 |\n| Sick | 6 |\n\n- [ ] Submit request\n- [x] Manager approval\n\nSee [policy](https://example.com/policy).",
    "## Onboarding Guide\n\nDo **this** first, then `run setup`.\n\n```ruby\nputs \"hello\"\n```\n\n| Step | Owner |\n| --- | --- |\n| 1. Laptop | IT |\n| 2. Accounts | HR |\n\n~~Old step~~ is gone.",
    "### Safety Rules\n\n> Follow these every shift.\n\n- Wear gear\n- Report issues\n\n| Item | Qty |\n| --- | --- |\n| Gloves | 2 |\n| Helmet | 1 |\n\n- [ ] Read handbook at [link](https://example.com/handbook)"
  ].freeze

  def self.new(
    company:,
    branch: nil,
    document_group: nil,
    category: nil,
    property_mapping: nil,
    title: nil,
    name: nil,
    description: nil,
    content: nil,
    body_markdown: nil,
    code: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil,
    **attrs
  )
    document_group ||= Seed::DocumentGroupService.create(company: company, branch: branch) if company
    branch ||= document_group.branch if document_group
    company ||= document_group.company if document_group

    Document.new(
      company: company,
      branch: branch,
      document_group: document_group,
      category: category,
      property_mapping: property_mapping,
      title: title || Faker::Lorem.sentence(word_count: 4),
      name: name || "Document #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      content: content || { "body" => Faker::Lorem.paragraph(sentence_count: 3) },
      body_markdown: body_markdown,
      code: code || "DOC-#{SecureRandom.hex(4).upcase}",
      lifecycle_status: lifecycle_status || Document.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Document.workflow_statuses.keys.sample,
      business_type: business_type || Document.business_types.keys.sample,
      discarded_at: discarded_at,
      **attrs
    )
  end

  def self.create(...)
    document = new(...)
    if document.category.nil? && document.company.present?
      document.category = Seed::CategoryService.random_for(
        company: document.company,
        resource_name: Document.model_name.plural
      )
    end
    if document.property_mapping.nil? && document.category.present?
      document.property_mapping = document.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(document)
    document.save!
    document
  end
end

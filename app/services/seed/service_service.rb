class Seed::ServiceService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    price: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil,
    **kwargs # Ignore extra kwargs for removed columns
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    lifecycle_status ||= Service.lifecycle_statuses.keys.sample
    workflow_status ||= Service.workflow_statuses.keys.sample

    name ||= "Service #{SecureRandom.hex(4)}"
    description ||= Faker::Lorem.sentence(word_count: 10)
    price_cents = if price.present?
      Money.from_amount(price, company.currency&.upcase || "USD").cents
    end

    Service.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      name: name,
      description: description,
      price_cents: price_cents,
      currency: company.currency,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type || Service.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  # Demo price in the company's currency. VND stays in whole dong; other
  # currencies use whole units (Money converts to cents).
  def self.demo_price(company)
    if company.currency.to_s == "vnd"
      rand(500_000..3_000_000).round(-4)
    else
      rand(50..300)
    end
  end

  def self.create(...)
    service = new(...)
    if service.category.nil? && service.company.present?
      service.category = Seed::CategoryService.random_for(
        company: service.company,
        resource_name: Service.model_name.plural
      )
    end
    if service.property_mapping.nil? && service.category.present?
      service.property_mapping = service.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(service)
    service.save!
    Seed::AttachmentService.attach(record: service, relation: :image_attachments, number: 2)
    service
  end
end

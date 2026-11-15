class Seed::RefundService
  def self.new(
    company:,
    branch: nil,
    customer: nil,
    order: nil,
    invoice: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    reason: nil,
    refund_type: Refund.refund_types.keys.sample,
    money_amount_cents: nil,
    currency: Refund.currencies.keys.sample,
    quantity: nil,
    lifecycle_status: :active,
    workflow_status: nil,
    created_by_employee: nil,
    skip_workflow: false,
    discarded_at: nil
  )
    raise "Cannot create refund: No company provided." if company.nil?

    Refund.new(
      company: company,
      branch: branch,
      customer: customer,
      order: order,
      invoice: invoice,
      category: category,
      property_mapping: property_mapping,
      name: name || "Refund #{Faker::Commerce.department}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "REF-#{SecureRandom.hex(4).upcase}",
      reason: reason || Faker::Lorem.sentence(word_count: 6),
      refund_type: refund_type,
      money_amount_cents: money_amount_cents || rand(1000..50000),
      currency: currency,
      quantity: quantity,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      created_by_employee: created_by_employee,
      skip_workflow: skip_workflow,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    refund = new(...)
    if refund.category.nil? && refund.company.present?
      refund.category = Seed::CategoryService.random_for(
        company: refund.company,
        resource_name: Refund.model_name.plural
      )
    end
    if refund.property_mapping.nil? && refund.category.present?
      refund.property_mapping = refund.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(refund)
    refund.save!
    refund
  end
end

class Seed::PurchaseService
  def self.new(
    company:,
    branch: nil,
    supplier: nil,
    category: nil,
    property_mapping: nil,
    name: nil,
    description: nil,
    code: nil,
    needed_by: nil,
    currency: Purchase.currencies.keys.sample,
    lifecycle_status: :active,
    workflow_status: nil,
    business_type: Purchase.business_types.keys.sample,
    workflow_step: nil,
    created_by_employee: nil,
    skip_workflow: false,
    discarded_at: nil
  )
    raise "Cannot create purchase: No company provided." if company.nil?

    Purchase.new(
      company: company,
      branch: branch,
      supplier: supplier,
      category: category,
      property_mapping: property_mapping,
      name: name || "Purchase #{Faker::Commerce.department}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "PUR-#{SecureRandom.hex(4).upcase}",
      needed_by: needed_by,
      currency: currency,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      workflow_step: workflow_step,
      created_by_employee: created_by_employee,
      skip_workflow: skip_workflow,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    purchase = new(...)
    if purchase.category.nil? && purchase.company.present?
      purchase.category = Seed::CategoryService.random_for(
        company: purchase.company,
        resource_name: Purchase.model_name.plural
      )
    end
    if purchase.property_mapping.nil? && purchase.category.present?
      purchase.property_mapping = purchase.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(purchase)
    purchase.save!
    purchase
  end
end

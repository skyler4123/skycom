class Seed::CustomerService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    user: nil,
    email: "customer_#{SecureRandom.hex}@gmail.com",
    name: Faker::Name.name,
    description: Faker::Lorem.sentence(word_count: 10),
    lifecycle_status: Customer.lifecycle_statuses.keys.sample,
    workflow_status: Customer.workflow_statuses.keys.sample,
    business_type: Customer.business_types.keys.sample,
    discarded_at: nil
  )
    Customer.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      user: user,
      name: name,
      email: email,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    customer = new(...)
    if customer.category.nil? && customer.company.present?
      customer.category = Seed::CategoryService.find_or_create_for(
        company: customer.company,
        resource_name: Customer.model_name.plural
      )
    end
    if customer.property_mapping.nil? && customer.category.present?
      customer.property_mapping = customer.category.property_mapping
    end
    Seed::PropertyPopulator.populate(customer)
    customer.save!
    customer
  end
end

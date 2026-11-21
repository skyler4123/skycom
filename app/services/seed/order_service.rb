class Seed::OrderService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    customer: nil,
    name: Faker::Company.buzzword,
    description: Faker::Lorem.sentence(word_count: 15),
    currency: Order.currencies.keys.sample,
    lifecycle_status: Order.lifecycle_statuses.keys.sample,
    workflow_status: Order.workflow_statuses.keys.sample,
    business_type: Order.business_types.keys.sample,
    fulfillment_channel: nil,
    fulfillment_status: nil,
    handed_over_at: nil,
    discarded_at: nil
  )
    channel = fulfillment_channel.presence || fulfillment_channel_for(business_type)
    handed_over = fulfillment_status.to_s == "handed_over"
    status = fulfillment_status.presence || "unfulfilled"

    Order.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      customer: customer,
      name: name,
      description: description,
      currency: currency,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      business_type: business_type,
      fulfillment_channel: channel,
      fulfillment_status: status,
      handed_over_at: handed_over_at.presence || (handed_over ? Time.current : nil),
      discarded_at: discarded_at
    )
  end

  def self.fulfillment_channel_for(business_type)
    case business_type.to_s
    when "online" then "local_delivery"
    when "phone" then "phone_hold"
    else "walk_in"
    end
  end

  def self.create(...)
    order = new(...)
    if order.category.nil? && order.company.present?
      order.category = Seed::CategoryService.random_for(
        company: order.company,
        resource_name: Order.model_name.plural
      )
    end
    if order.property_mapping.nil? && order.category.present?
      order.property_mapping = order.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(order)
    order.save!
    order
  end
end

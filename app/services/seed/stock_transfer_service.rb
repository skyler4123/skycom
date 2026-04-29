class Seed::StockTransferService
  def self.new(
    company:,
    branch: nil,
    product:,
    category: nil,
    appoint_from: nil,
    appoint_to: nil,
    appoint_for: nil,
    appoint_by: nil,
    name: nil,
    description: nil,
    code: nil,
    quantity: nil,
    lifecycle_status: nil,
    workflow_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create stock transfer: No company provided." if company.nil?
    raise "Cannot create stock transfer: No product provided." if product.nil?

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    StockTransfer.new(
      company: company,
      branch: branch,
      product: product,
      category: category,
      appoint_from: appoint_from,
      appoint_to: appoint_to,
      appoint_for: appoint_for,
      appoint_by: appoint_by,
      name: name || "StockTransfer #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "STKXN-#{SecureRandom.hex(4).upcase}",
      quantity: quantity || rand(1..100),
      lifecycle_status: lifecycle_status || StockTransfer.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || StockTransfer.workflow_statuses.keys.sample,
      business_type: business_type || StockTransfer.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    transfer = new(...)
    transfer.save!
    transfer
  end
end
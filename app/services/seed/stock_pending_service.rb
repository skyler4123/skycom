class Seed::StockPendingService
  def self.create(
    company:,
    warehouse:,
    stock:,
    quantity: nil,
    business_type: :manual,
    name: nil,
    reason: nil,
    release: false
  )
    raise "Cannot create stock pending: No company provided." if company.nil?
    raise "Cannot create stock pending: No warehouse provided." if warehouse.nil?
    raise "Cannot create stock pending: No stock provided." if stock.nil?

    quantity ||= rand(1..3)
    result = StockPendings::HoldService.call(
      company: company, warehouse: warehouse, stock: stock,
      quantity: quantity, business_type: business_type,
      name: name || "StockPending #{Faker::Lorem.sentence(word_count: 3)}",
      reason: reason || Faker::Lorem.sentence(word_count: 8)
    )
    raise "Cannot create stock pending: #{result[:errors].to_sentence}" unless result[:success]

    pending = result[:stock_pending]
    if release
      release_result = StockPendings::ReleaseService.call(stock_pending: pending)
      raise "Cannot release stock pending: #{release_result[:errors].to_sentence}" unless release_result[:success]

      pending.reload
    end
    pending
  end
end

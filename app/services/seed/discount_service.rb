class Seed::DiscountService
  def self.new(
    company:,
    discount_group:,
    code: nil,
    status: :unused,
    order: nil,
    invoice: nil,
    customer: nil,
    employee: nil,
    amount_cents: nil,
    used_at: nil,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create discount: No company or discount group provided." if company.nil? || discount_group.nil?

    Discount.new(
      company: company,
      discount_group: discount_group,
      code: code || "DSC-#{SecureRandom.hex(4).upcase}",
      status: status,
      order: order,
      invoice: invoice,
      customer: customer,
      employee: employee,
      amount_cents: amount_cents,
      used_at: used_at,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    discount = new(...)
    discount.save!
    discount
  end
end

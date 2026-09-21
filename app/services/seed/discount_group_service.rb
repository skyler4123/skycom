class Seed::DiscountGroupService
  def self.new(
    company:,
    name:,
    prefix:,
    discount_type: :percentage,
    percentage: nil,
    amount_cents: nil,
    max_amount_cents: nil,
    total_budget_cents: nil,
    start_at: nil,
    end_at: nil,
    currency: :usd,
    campaign_status: :draft,
    description: nil,
    code: nil,
    lifecycle_status: :active,
    discarded_at: nil
  )
    raise "Cannot create discount group: No company provided." if company.nil?

    percentage = 10.0 if discount_type.to_s == "percentage" && percentage.nil?
    amount = 500 if discount_type.to_s == "fixed_amount" && amount_cents.nil?

    DiscountGroup.new(
      company: company,
      name: name,
      description: description,
      code: code || "DGRP-#{SecureRandom.hex(4).upcase}",
      prefix: prefix,
      discount_type: discount_type,
      percentage: percentage,
      amount_cents: amount,
      max_amount_cents: max_amount_cents,
      total_budget_cents: total_budget_cents,
      start_at: start_at || 1.day.ago,
      end_at: end_at || 30.days.from_now,
      currency: currency,
      campaign_status: campaign_status,
      lifecycle_status: lifecycle_status,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    group = new(...)
    group.save!
    group
  end
end

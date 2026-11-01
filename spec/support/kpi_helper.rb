module KpiHelper
  # Builds a paid order with one product line so revenue and count KPIs both
  # have deterministic input. The company is forced to USD because
  # Analytics::RevenueCalculator converts USD totals to cents.
  def create_paid_order(company:, salesperson: nil, created_at: Time.current, total_price: 50.0, workflow_status: :paid)
    # update_columns skips before_validation :assign_currency_from_country,
    # which would otherwise restore the random country's currency.
    company.update_columns(currency: Company.currencies[:usd]) unless company.currency_usd?

    customer = create(:customer, company: company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "orders")
    order = company.orders.create!(
      customer: customer,
      category: category,
      property_mapping: category.default_property_mapping,
      name: "KPI Order #{SecureRandom.hex(4)}",
      currency: :usd,
      business_type: :in_store,
      workflow_status: workflow_status,
      salesperson: salesperson,
      created_at: created_at
    )

    OrderProductAppointment.create!(
      company: company,
      order: order,
      product: create(:product, company: company),
      quantity: 1,
      unit_price: total_price,
      total_price: total_price
    )

    order
  end
end

RSpec.configure do |config|
  config.include KpiHelper
end

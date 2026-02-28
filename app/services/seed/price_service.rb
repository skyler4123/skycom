
# This service seeds the database with Cart records. Each cart is
# associated with a CartGroup and a Branch.

class Seed::PriceService
  def self.create(
    amount: rand(10..100),
    currency_code: :usd
  )
    Price.find_or_create_by!(
      amount: amount,
      currency_code: currency_code
    )
  end
end
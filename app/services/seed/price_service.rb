
# This service seeds the database with Cart records. Each cart is
# associated with a CartGroup and a Branch.

class Seed::PriceService
  CENT_LIKE_CURRENCIES = %i[usd aud eur].freeze

  def self.create(
    amount: rand(10..100),
    currency_code: :usd
  )
    amount_value = amount.to_s.to_f

    if CENT_LIKE_CURRENCIES.include?(currency_code.to_sym)
      amount_in_cents = (amount_value * 100).round
    else
      amount_in_cents = amount_value.round
    end

    Price.find_or_create_by!(
      amount: amount_in_cents,
      currency_code: currency_code
    )
  end
end

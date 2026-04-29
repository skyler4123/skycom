# How to use: Dont update records, always find_or_create_by! to reuse existing periods.

# app/models/price.rb
class Price < ApplicationRecord
  include ImmutableRecordConcern

  has_many :period_prices, dependent: :destroy

  # 1. Standard Rails Enum for Currencies
  # Use lowercase ISO codes as keys to keep integration simple.
  enum :currency_code, {
    usd: 0,
    vnd: 1,
    aud: 2,
    eur: 3
  }, prefix: true

  # 2. Money-Rails Configuration
  # We map the gem's 'cents' logic to your 'amount' column.
  monetize :amount, 
           as: "value",                # Accessor will be .value (e.g., price.value.format)
           with_model_currency: :currency_iso, 
           disable_validation: true     # We'll handle validations manually for more control

  # 3. Validations
  validates :amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency_code, presence: true

  # 4. Helper for Money-Rails
  # The gem expects a string like "USD", so we convert the enum on the fly.
  def currency_iso
    currency_code&.upcase || "USD"
  end
end

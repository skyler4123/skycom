# How to use: Dont update records, always find_or_create_by! to reuse existing periods.

# app/models/price.rb
class Price < ApplicationRecord
  include ImmutableRecordConcern

  has_many :period_prices, dependent: :destroy

  # 1. Define the Enum
  # Map integers to currency codes. Add new currencies to the END of the list.
  # DO NOT change the integer value of existing currencies once you have data.
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  # 2. Validations
  # Rails enum validation happens automatically on assignment,
  # but presence ensures we don't save nils.
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency_code, presence: true

  # Enforce Uniqueness
  validates :amount, uniqueness: {
    scope: :currency_code,
    message: "already exists for this currency"
  }

  # Helper: distinct display string since 'currency' now returns a string like "usd"
  def display_currency
    currency.upcase
  end
end

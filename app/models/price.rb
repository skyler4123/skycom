# app/models/price.rb
class Price < ApplicationRecord
  # 1. Define the Enum
  # Map integers to currency codes. Add new currencies to the END of the list.
  # DO NOT change the integer value of existing currencies once you have data.
  enum :currency, { 
    usd: 0, 
    eur: 1, 
    gbp: 2, 
    jpy: 3, 
    aud: 4, 
    cad: 5,
    vnd: 6
    # add more here...
  }, default: :usd

  # 2. Validations
  # Rails enum validation happens automatically on assignment, 
  # but presence ensures we don't save nils.
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  # Enforce Uniqueness
  validates :amount, uniqueness: { 
    scope: :currency,
    message: "already exists for this currency"
  }

  # 3. Reusable Logic
  # We downcase the currency input to ensure it matches the enum keys
  def self.reusable_create(amount:, currency: :usd)
    # The currency argument can be a string "USD", symbol :usd, or integer 0
    # Rails handles the conversion automatically if we pass it to find_or_create_by
    find_or_create_by(
      amount: amount,
      currency: currency.to_s.downcase
    )
  end

  # Helper: distinct display string since 'currency' now returns a string like "usd"
  def display_currency
    currency.upcase
  end
end


# # 1. Create/Find a Price (using a symbol)
# # Behind the scenes, Rails queries: SELECT * FROM prices WHERE amount = 50 AND currency = 1
# price_eur = Price.reusable_price(amount: 50, currency: :eur)

# # 2. Create/Find a Price (using a string)
# price_usd = Price.reusable_price(amount: 10, currency: "USD")

# # 3. Using the Object
# puts price_eur.currency  # => "eur" (Rails translates the int back to string)
# puts price_eur.amount    # => 50.0
# puts price_eur.eur?      # => true
# puts price_eur.usd?      # => false

# # 4. Linking to another model
# product = Product.create(name: "T-Shirt", price: price_usd)
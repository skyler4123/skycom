module PeriodPriceConcern
  extend ActiveSupport::Concern

  included do
    has_many :period_prices, as: :period_priceable, dependent: :destroy
    
    # FIX: These must be plural (:period_prices) to match the association above
    has_many :periods, through: :period_prices
    has_many :prices, through: :period_prices
  end

  # 1. Find the PeriodPrice active at a specific time (defaults to NOW)
  def period_price_at(time = Time.current)
    period_prices.joins(:period).where(
      "periods.start_at <= ? AND (periods.end_at IS NULL OR periods.end_at > ?)",
      time,
      time
    ).first
  end

  # 2. Get the current active wrapper
  def current_period_price
    period_price_at(Time.current)
  end

  # 3. Get the actual Money value
  def current_price
    current_period_price&.price
  end

  # 4. Get the actual Time Range
  def current_period
    current_period_price&.period
  end
end

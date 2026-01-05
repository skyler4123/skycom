module PricePeriodConcern
  extend ActiveSupport::Concern

  included do
    has_many :price_periods, as: :price_periodable, dependent: :destroy
    
    # FIX: These must be plural (:price_periods) to match the association above
    has_many :periods, through: :price_periods
    has_many :prices, through: :price_periods
  end

  # 1. Find the PricePeriod active at a specific time (defaults to NOW)
  def price_period_at(time = Time.current)
    price_periods.joins(:period).where(
      "periods.start_at <= ? AND (periods.end_at IS NULL OR periods.end_at > ?)",
      time,
      time
    ).first
  end

  # 2. Get the current active wrapper
  def current_price_period
    price_period_at(Time.current)
  end

  # 3. Get the actual Money value
  def current_price
    current_price_period&.price
  end

  # 4. Get the actual Time Range
  def current_period
    current_price_period&.period
  end
end

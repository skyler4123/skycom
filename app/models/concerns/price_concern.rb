# app/models/concerns/price_concern.rb
module PriceConcern
  extend ActiveSupport::Concern

  included do
    has_many :price_appointments, as: :appoint_to, dependent: :destroy

    # Direct access to all unique Price records assigned to this model
    has_many :prices, through: :price_appointments, source: :price

    has_one :current_price_appointment, -> {
              where(lifecycle_status: :active).order(created_at: :desc)
            }, as: :appoint_to, class_name: "PriceAppointment"

    has_one :db_price, through: :current_price_appointment, source: :price
  end

  def price
    cache_key = "#{cache_key_with_version}/current_price"
    Rails.cache.fetch(cache_key) { db_price&.value || Money.new(0, "USD") }
  end

  # Setter: accepts { amount: 5.00, currency_code: :usd }
  def price=(options)
    return if options.blank?

    amount = options[:amount]
    # Default changed to :usd
    currency_code = options[:currency_code] || :usd

    # from_amount handles decimals ($5.00) and large integers (250,000 VND) correctly
    money_item = Money.from_amount(amount, currency_code.to_s.upcase)

    attach_price(
      amount: money_item.cents,
      currency_code: currency_code
    )
  end

  def attach_price(amount:, currency_code: :usd, **options)
    # Ensure we are working with cents for the immutable Price record
    target_price = Price.find_or_create_by!(
      amount: amount,
      currency_code: currency_code.to_s.downcase.to_sym
    )

    self.transaction do
      b_type = options[:business_type] || :base

      price_appointments.where(business_type: b_type)
                        .where.not(lifecycle_status: :archived)
                        .update_all(lifecycle_status: :archived)

      price_appointments.create!(
        price: target_price,
        period: options[:period],
        lifecycle_status: :active,
        workflow_status: options[:workflow_status] || :approved,
        business_type: b_type,
        appoint_from: options[:from],
        appoint_for: options[:for],
        appoint_by: options[:by]
      )

      self.touch if self.persisted?
    end
  end
end

class SubscriptionPlan < ApplicationRecord
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  has_many :order_subscription_plan_appointments, dependent: :destroy
  has_many :orders, through: :order_subscription_plan_appointments
  has_many :branch_subscription_plan_appointments, dependent: :destroy
  has_many :branches, through: :branch_subscription_plan_appointments
  has_many :subscription_group_subscription_plan_appointments, dependent: :destroy
  has_many :subscription_groups, through: :subscription_group_subscription_plan_appointments

  belongs_to :company
  belongs_to :branch, optional: true
end

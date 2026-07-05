class SubscriptionPlan < ApplicationRecord
  attribute :features, :jsonb, default: {}
  attribute :limits, :jsonb, default: {}
  attribute :metadata, :jsonb, default: {}

  has_many :subscription_plan_appointments, dependent: :destroy

  belongs_to :company
  belongs_to :branch, optional: true
end

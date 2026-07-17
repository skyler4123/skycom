class SubscriptionPlan < ApplicationRecord
  has_many :subscription_plan_appointments, dependent: :destroy

  belongs_to :company
  belongs_to :branch, optional: true
end

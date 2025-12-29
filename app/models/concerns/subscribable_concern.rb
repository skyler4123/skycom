module SubscribableConcern
  extend ActiveSupport::Concern

  included do
    has_many :subscription_appointments, as: :appoint_to, dependent: :destroy
    has_many :subscriptions, through: :subscription_appointments
    
    def subscribe(subscription, appoint_from:, appoint_for:, appoint_by: nil, name: nil, description: nil, code: nil, lifecycle_status: nil, workflow_status: nil, business_type: nil)
      subscription_appointments.create!(
        subscription: subscription,
        appoint_from: appoint_from,
        appoint_for: appoint_for,
        appoint_by: appoint_by,
        name: name,
        description: description,
        code: code,
        lifecycle_status: lifecycle_status,
        workflow_status: workflow_status,
        business_type: business_type
      )
    end
  end
end

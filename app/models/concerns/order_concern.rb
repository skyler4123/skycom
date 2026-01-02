module OrderConcern
  extend ActiveSupport::Concern

  included do
    has_many :order_appointments, as: :appoint_to, dependent: :destroy
    has_many :orders, through: :order_appointments
  end
end

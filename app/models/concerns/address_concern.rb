module AddressConcern
  extend ActiveSupport::Concern

  included do
    has_one :address_appointment, as: :appoint_to, dependent: :destroy
    has_one :address, dependent: :destroy, through: :address_appointment
  end
end

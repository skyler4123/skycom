# app/models/reservation.rb
class Reservation < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # Standard ERP enums based on your schema pattern
  enum :lifecycle_status, { active: 0, archived: 1, deleted: 2 }
  enum :workflow_status, { draft: 0, confirmed: 1, checked_in: 2, completed: 3, cancelled: 4 }
  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping
  has_many :reservation_appointments, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end

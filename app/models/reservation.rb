# app/models/reservation.rb
class Reservation < ApplicationRecord
  attribute :metadata, :jsonb, array: true, default: []
  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  include CategoryConcern
  include PropertyMappingConcern

  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping
  has_many :reservation_appointments, dependent: :destroy

  # Standard ERP enums based on your schema pattern
  enum :lifecycle_status, { active: 0, archived: 1, deleted: 2 }
  enum :workflow_status, { draft: 0, confirmed: 1, checked_in: 2, completed: 3, cancelled: 4 }

  validates :code, presence: true, uniqueness: true
end

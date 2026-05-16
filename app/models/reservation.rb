# app/models/reservation.rb
class Reservation < ApplicationRecord
  belongs_to :company
  has_many :reservation_appointments, dependent: :destroy

  # Standard ERP enums based on your schema pattern
  enum :lifecycle_status, { active: 0, archived: 1, deleted: 2 }
  enum :workflow_status, { draft: 0, confirmed: 1, checked_in: 2, completed: 3, cancelled: 4 }

  validates :code, presence: true, uniqueness: true
end

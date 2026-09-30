# app/models/calendar_event_location.rb
#
# Join: which rooms a booking occupies. Supports the multi-room case (e.g. a
# procedure needing a surgery room plus a recovery bay).
#
# @see docs/CALENDAR.md
class CalendarEventLocation < ApplicationRecord
  belongs_to :company
  belongs_to :calendar_event
  belongs_to :calendar_location

  # --- Scopes ---
  scope :primary_rooms, -> { where(role: "primary") }

  # --- Validations ---
  validates :role, presence: true, inclusion: { in: CALENDAR_LOCATION_ROLES }
  validates :calendar_location_id, uniqueness: { scope: :calendar_event_id }
  validate :location_belongs_to_same_company

  private

  def location_belongs_to_same_company
    return if calendar_location.blank?
    return if calendar_location.company_id == (company_id || company&.id)


    errors.add(:calendar_location, "must belong to the same company")
  end
end

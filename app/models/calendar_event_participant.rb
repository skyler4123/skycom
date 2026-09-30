# app/models/calendar_event_participant.rb
#
# Join: who the booking is for — the "Patient A" of a dental clinic. Kept as a
# join table rather than a column on calendar_events so a group appointment
# (a family, a class) stays expressible.
#
# @see docs/CALENDAR.md
class CalendarEventParticipant < ApplicationRecord
  belongs_to :company
  belongs_to :calendar_event
  belongs_to :calendar_participant

  # --- Scopes ---
  scope :primary_attendees, -> { where(role: "primary") }

  # --- Validations ---
  validates :role, presence: true, inclusion: { in: CALENDAR_PARTICIPANT_ROLES }
  validates :calendar_participant_id, uniqueness: { scope: :calendar_event_id }
  validate :participant_belongs_to_same_company

  private

  def participant_belongs_to_same_company
    return if calendar_participant.blank?
    return if calendar_participant.company_id == (company_id || company&.id)


    errors.add(:calendar_participant, "must belong to the same company")
  end
end

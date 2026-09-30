# app/models/calendar_event_practitioner.rb
#
# Join: which practitioners are assigned to a booking, and in what capacity.
# This is the many-to-many that lets one event need a lead dentist plus an
# assistant. `role` is a plain string validated against
# CALENDAR_PRACTITIONER_ROLES — the allowed sets differ per resource type, so a
# single shared enum would be wrong.
#
# @see docs/CALENDAR.md
class CalendarEventPractitioner < ApplicationRecord
  belongs_to :company
  belongs_to :calendar_event
  belongs_to :calendar_practitioner

  # --- Scopes ---
  scope :leads, -> { where(role: "lead") }
  scope :required, -> { where(required: true) }

  # --- Validations ---
  validates :role, presence: true, inclusion: { in: CALENDAR_PRACTITIONER_ROLES }
  validates :calendar_practitioner_id, uniqueness: { scope: :calendar_event_id }
  validate :practitioner_belongs_to_same_company

  private

  def practitioner_belongs_to_same_company
    return if calendar_practitioner.blank?
    return if calendar_practitioner.company_id == (company_id || company&.id)


    errors.add(:calendar_practitioner, "must belong to the same company")
  end
end

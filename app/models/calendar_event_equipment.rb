# app/models/calendar_event_equipment.rb
#
# Join: which devices a booking reserves — the "Machine T" of a dental clinic.
#
# @see docs/CALENDAR.md
class CalendarEventEquipment < ApplicationRecord
  belongs_to :company
  belongs_to :calendar_event
  belongs_to :calendar_equipment

  # --- Scopes ---
  scope :primary_machines, -> { where(role: "primary") }

  # --- Validations ---
  validates :role, presence: true, inclusion: { in: CALENDAR_EQUIPMENT_ROLES }
  validates :calendar_equipment_id, uniqueness: { scope: :calendar_event_id }
  validate :equipment_belongs_to_same_company

  private

  def equipment_belongs_to_same_company
    return if calendar_equipment.blank?
    return if calendar_equipment.company_id == (company_id || company&.id)


    errors.add(:calendar_equipment, "must belong to the same company")
  end
end

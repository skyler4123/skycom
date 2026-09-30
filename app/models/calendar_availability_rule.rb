# app/models/calendar_availability_rule.rb
#
# Raw working hours for a practitioner or a room. This module stores the hours
# but does not yet compute free slots from them — that is the future
# Calendar::Adapter#available_slots seam. What the board needs today is the
# hours themselves, plus blackout blocks (is_unavailable) for leave.
#
# A rule belongs to exactly one owner: a practitioner OR a location. Enforced by
# a DB CHECK constraint and re-checked here for a friendly error message.
#
# @see docs/CALENDAR.md
class CalendarAvailabilityRule < ApplicationRecord
  include Calendar::SyncableConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_practitioner, optional: true
  belongs_to :calendar_location, optional: true

  # --- Scopes ---
  scope :working_hours, -> { where(is_unavailable: false) }
  scope :blackouts, -> { where(is_unavailable: true) }
  scope :ordered, -> { order(:priority, :start_time) }
  scope :effective_on, ->(date) {
    where("effective_from IS NULL OR effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }

  # --- Validations ---
  validates :start_time, :end_time, presence: true
  validates :timezone, presence: true
  validates :priority, numericality: { only_integer: true }
  validate :times_well_formed
  validate :exactly_one_owner
  validate :owner_belongs_to_same_company

  # Applies to this ISO weekday (1 = Monday .. 7 = Sunday)? A rule with no
  # days listed applies to every day.
  def covers_weekday?(date)
    return true if days_of_week.blank?

    days_of_week.include?(date.wday)
  end

  def working?
    !is_unavailable?
  end

  def blackout?
    is_unavailable?
  end

  def to_s
    name.presence || "#{owner_label} #{start_time}–#{end_time}"
  end

  def owner_label
    calendar_practitioner&.name || calendar_location&.name || "Unassigned"
  end

  private

  def times_well_formed
    errors.add(:start_time, "must be HH:MM") unless start_time.to_s.match?(CALENDAR_TIME_FORMAT)
    errors.add(:end_time, "must be HH:MM") unless end_time.to_s.match?(CALENDAR_TIME_FORMAT)
    return unless start_time.to_s.match?(CALENDAR_TIME_FORMAT) && end_time.to_s.match?(CALENDAR_TIME_FORMAT)
    return if end_time > start_time

    errors.add(:end_time, "must be after the start time (overnight spans are not supported)")
  end

  def exactly_one_owner
    if calendar_practitioner_id.present? && calendar_location_id.present?
      errors.add(:base, "A rule belongs to either a practitioner or a location, not both")
    elsif calendar_practitioner_id.blank? && calendar_location_id.blank?
      errors.add(:base, "A rule must belong to a practitioner or a location")
    end
  end

  def owner_belongs_to_same_company
    own = company_id || company&.id
    [ calendar_practitioner, calendar_location ].compact.each do |owner|
      next if owner.company_id == own

      errors.add(:base, "#{owner_label} must belong to the same company")
    end
  end
end

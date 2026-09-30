# app/models/calendar_event.rb
#
# A single booking on the calendar. Owns the time window and the status
# lifecycle; the four calendar_event_* join tables carry the assigned
# practitioners, locations, equipment and participants.
#
# Conflict detection is a model-level validation (not a service-only concern)
# so a double-booking is rejected on every write path — controller, console,
# rake task and seeder alike. See docs/CALENDAR.md §5.
#
# @see docs/CALENDAR.md
class CalendarEvent < ApplicationRecord
  include Calendar::SyncableConcern

  # Statuses that still occupy the resource. A cancelled or no-show event
  # releases its practitioners / room / machine for rebooking.
  BLOCKING_STATUSES = %w[pending confirmed in_progress].freeze

  # Statuses the board hides. A completed or no-show appointment still happened
  # and belongs on the grid; only a cancelled one is removed.
  HIDDEN_ON_BOARD_STATUSES = %w[cancelled].freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :status, CALENDAR_EVENT_STATUSES, prefix: true, default: :pending
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_procedure
  belongs_to :branch, optional: true
  belongs_to :source, polymorphic: true, optional: true
  has_many :calendar_event_practitioners, dependent: :destroy
  has_many :calendar_practitioners, through: :calendar_event_practitioners
  has_many :calendar_event_locations, dependent: :destroy
  has_many :calendar_locations, through: :calendar_event_locations
  has_many :calendar_event_equipment, dependent: :destroy
  has_many :calendar_equipment, through: :calendar_event_equipment
  has_many :calendar_event_participants, dependent: :destroy
  has_many :calendar_participants, through: :calendar_event_participants

  # --- Scopes ---
  scope :ordered, -> { order(:starts_at) }
  # nil lifecycle_status means "never set" == active (see CalendarProcedure).
  scope :active, -> { where(lifecycle_status: [ nil, :active ]) }
  scope :blocking, -> { where(status: BLOCKING_STATUSES) }
  scope :cancelled, -> { where(status: :cancelled) }
  # What the board grid renders: everything except a cancelled booking.
  scope :board_visible, -> { where.not(status: HIDDEN_ON_BOARD_STATUSES) }
  scope :upcoming, -> { where(arel_table[:starts_at].gteq(Time.current)).order(:starts_at) }

  # Events that overlap the given half-open window. Shared endpoints are NOT an
  # overlap: 10:00–11:00 and 11:00–12:00 both qualify, 10:00–11:30 and
  # 10:30–11:30 do not.
  scope :overlapping, ->(range_start, range_end) {
    where(arel_table[:starts_at].lt(range_end))
      .where(arel_table[:ends_at].gt(range_start))
  }

  # --- Validations ---
  validates :starts_at, :ends_at, presence: true
  validates :status, presence: true
  validates :timezone, presence: true
  validates :title, length: { maximum: 255 }, allow_blank: true
  validate :ends_after_starts
  validate :procedure_belongs_to_same_company
  validate :no_resource_conflicts, on: %i[create update]

  # --- Callbacks ---
  after_update :stamp_cancellation, if: :saved_change_to_status?

  # --- Public methods ---
  # Pending assignment ids. Calendar::BookingService sets these before saving so
  # Calendar::ConflictChecker can see a brand new booking's resources during
  # validation — the join rows do not exist yet at that point. Left unset, each
  # reader falls back to the ids already persisted on the join rows.
  attr_writer :practitioner_ids, :location_ids, :equipment_ids, :participant_ids

  def practitioner_ids
    @practitioner_ids || calendar_event_practitioners.pluck(:calendar_practitioner_id)
  end

  def location_ids
    @location_ids || calendar_event_locations.pluck(:calendar_location_id)
  end

  def equipment_ids
    @equipment_ids || calendar_event_equipment.pluck(:calendar_equipment_id)
  end

  def participant_ids
    @participant_ids || calendar_event_participants.pluck(:calendar_participant_id)
  end

  def duration_minutes
    return 0 if starts_at.blank? || ends_at.blank?

    ((ends_at - starts_at) / 60.0).round
  end

  def display_title
    title.presence || calendar_procedure&.name
  end

  def display_color
    calendar_procedure&.color.presence || CALENDAR_DEFAULT_COLOR
  end

  def blocking?
    BLOCKING_STATUSES.include?(status)
  end

  def cancelled?
    status_cancelled?
  end

  def confirm!
    update!(status: :confirmed, confirmed_at: Time.current, cancellation_reason: nil, cancelled_at: nil)
  end

  def cancel!(reason = nil)
    update!(status: :cancelled, cancelled_at: Time.current, cancellation_reason: reason)
  end

  def complete!
    update!(status: :completed)
  end

  def primary_practitioner
    lead = calendar_event_practitioners.find_by(role: "lead")
    lead&.calendar_practitioner
  end

  def primary_location
    calendar_event_locations.find_by(role: "primary")&.calendar_location
  end

  # Flattened shape for the board widget (FullCalendar-compatible field names).
  def to_calendar_payload
    {
      id: id,
      title: display_title,
      start: starts_at&.iso8601,
      end: ends_at&.iso8601,
      allDay: all_day,
      backgroundColor: display_color,
      borderColor: display_color,
      editable: !cancelled?,
      extendedProps: {
        status: status,
        procedure_id: calendar_procedure_id,
        procedure_name: calendar_procedure&.name,
        location_name: primary_location&.name,
        participants: calendar_participants.map(&:name),
        practitioners: calendar_practitioners.map(&:name)
      }
    }
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after the start time") if ends_at <= starts_at
  end

  def procedure_belongs_to_same_company
    return if calendar_procedure.blank?
    return if calendar_procedure.company_id == own_company_id

    errors.add(:calendar_procedure, "must belong to the same company")
  end

  # `company_id` is only populated once the (lazily built) association has been
  # read, so fall back to the association itself before giving up on the check.
  def own_company_id
    company_id || company&.id
  end

  # Hard block on double-booking. Delegates the overlap maths to
  # Calendar::ConflictChecker so the same rules can be previewed by the booking
  # form before the user submits.
  def no_resource_conflicts
    return if starts_at.blank? || ends_at.blank? || cancelled?
    return unless will_save_change_to_starts_at? || will_save_change_to_ends_at? ||
                  will_save_change_to_status? || new_record?

    Calendar::ConflictChecker.new(self).conflicts.each do |conflict|
      errors.add(conflict[:attribute] || :base, conflict[:message])
    end
  end

  def stamp_cancellation
    return unless status_cancelled? && cancelled_at.blank?

    update_column(:cancelled_at, Time.current)
  end
end

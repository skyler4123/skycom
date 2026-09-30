# app/models/calendar_procedure.rb
#
# A bookable appointment type — "Removal teeth", "Dental Cleaning". This is the
# calendar module's closest analogue to a Cal.com EventType, except it is first
# class: the board, the booking form and conflict detection all read from it.
#
# A procedure always names the position that performs it, so a booking knows
# which practitioners are eligible before anything is assigned.
#
# @see docs/CALENDAR.md
class CalendarProcedure < ApplicationRecord
  include Calendar::SyncableConcern
  include Calendar::SourceLinkConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  source_links_to "Service"

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_position
  belongs_to :branch, optional: true
  has_many :calendar_events, dependent: :restrict_with_error

  # --- Scopes ---
  scope :ordered, -> { order(:name) }
  # lifecycle_status is nullable in this schema and nil means "never set" ==
  # active, so the picker must treat nil as active or freshly seeded records
  # would vanish from the booking form.
  scope :active, -> { where(lifecycle_status: [ nil, :active ]) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { scope: :company_id },
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase and hyphen-separated" }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :buffer_before_minutes, :buffer_after_minutes,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :requires_practitioners, numericality: { only_integer: true, greater_than: 0 }
  validates :color, presence: true
  validate :position_belongs_to_same_company

  # Elapsed minutes including both buffers — the window a booking must reserve.
  def blocked_minutes
    duration_minutes + buffer_before_minutes + buffer_after_minutes
  end

  def display_color
    color.presence || calendar_position&.color
  end

  private

  def position_belongs_to_same_company
    return if calendar_position.blank?
    return if calendar_position.company_id == own_company_id

    errors.add(:calendar_position, "must belong to the same company")
  end

  # `company_id` is only populated once the (lazily built) association has been
  # read, so fall back to the association itself before giving up on the check.
  def own_company_id
    company_id || company&.id
  end
end

# app/models/calendar_practitioner.rb
#
# Bridge from a bookable position to the people who can be booked for it —
# the "Doctor D" / "Nurse F" rows of a dental clinic. Points at an Employee or
# a User through the polymorphic source pair; the calendar module never
# references those models directly.
#
# @see docs/CALENDAR.md
class CalendarPractitioner < ApplicationRecord
  include Calendar::SyncableConcern
  include Calendar::SourceLinkConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  source_links_to "Employee", "User"
  requires_source_link true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_position
  belongs_to :branch, optional: true
  has_many :calendar_event_practitioners, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_practitioners
  has_many :calendar_availability_rules, dependent: :destroy

  # --- Scopes ---
  scope :ordered, -> { order(:calendar_position_id, :name) }
  scope :bookable, -> { where(bookable: true, lifecycle_status: [ nil, :active ]) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :source_id, uniqueness: { scope: [ :company_id, :source_type ] }
  validate :position_belongs_to_same_company

  # Falls back to the position colour when the practitioner has none.
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

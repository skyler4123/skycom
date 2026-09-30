# app/models/calendar_location.rb
#
# A bookable place — the "Room C" of a dental clinic. Optionally bridges to a
# Facility or Branch; a location may also be calendar-only (a room that has no
# ERP record of its own yet).
#
# @see docs/CALENDAR.md
class CalendarLocation < ApplicationRecord
  include Calendar::SyncableConcern
  include Calendar::SourceLinkConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  source_links_to "Facility", "Branch"

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  has_many :calendar_event_locations, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_locations
  has_many :calendar_availability_rules, dependent: :destroy

  # --- Scopes ---
  scope :ordered, -> { order(:name) }
  scope :bookable, -> { where(bookable: true, lifecycle_status: [ nil, :active ]) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :color, presence: true
end

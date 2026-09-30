# app/models/calendar_equipment.rb
#
# A bookable device — the "Machine T" of a dental clinic (X-ray, autoclave).
# Optionally bridges to a Stock or Product record; may also be calendar-only.
#
# @see docs/CALENDAR.md
class CalendarEquipment < ApplicationRecord
  include Calendar::SyncableConcern
  include Calendar::SourceLinkConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  source_links_to "Stock", "Product"

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  has_many :calendar_event_equipment, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_equipment

  # --- Scopes ---
  scope :ordered, -> { order(:name) }
  scope :bookable, -> { where(bookable: true, lifecycle_status: [ nil, :active ]) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :color, presence: true
end

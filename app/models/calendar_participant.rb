# app/models/calendar_participant.rb
#
# The person an appointment is for — the "Patient A" of a dental clinic.
# Optionally bridges to a Customer; may also be a walk-in with no ERP record.
#
# @see docs/CALENDAR.md
class CalendarParticipant < ApplicationRecord
  include Calendar::SyncableConcern
  include Calendar::SourceLinkConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  source_links_to "Customer"

  # --- Associations ---
  belongs_to :company
  has_many :calendar_event_participants, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_participants

  # --- Scopes ---
  scope :ordered, -> { order(:name) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end

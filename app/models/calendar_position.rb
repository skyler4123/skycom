# app/models/calendar_position.rb
#
# A bookable job position — "Dentist", "Dental Assistant". Positions describe
# WHAT kind of practitioner a booking needs; CalendarPractitioner records the
# people who fill them. Replaces the old, unfinished `events` domain.
#
# @see docs/CALENDAR.md
class CalendarPosition < ApplicationRecord
  include Calendar::SyncableConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :calendar_practitioners, dependent: :destroy
  has_many :calendar_procedures, dependent: :destroy

  # --- Scopes ---
  scope :ordered, -> { order(:sort_order, :name) }
  scope :bookable, -> { where(lifecycle_status: [ nil, :active ]) }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :default_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :color, presence: true

  def duration_minutes
    default_duration_minutes
  end
end

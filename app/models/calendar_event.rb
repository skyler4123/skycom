class CalendarEvent < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :attendees, :meeting_url, :location_type, :external_uid

  # --- Enums ---
  enum :status, { pending: 0, confirmed: 1, cancelled: 2, rescheduled: 3 }, default: :pending
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_integration, optional: true
  belongs_to :schedulable, polymorphic: true, optional: true
  has_many :calendar_sync_mappings, dependent: :destroy

  # --- Scopes ---
  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(starts_at: :asc) }

  # --- Validations ---
  validates :title, :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end

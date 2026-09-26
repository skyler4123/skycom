class CalendarSyncMapping < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :calendar_event
  belongs_to :calendar_integration

  # --- Validations ---
  validates :external_event_id, presence: true,
    uniqueness: { scope: :calendar_integration_id }

  before_validation :derive_company_from_event_or_integration

  private

  def derive_company_from_event_or_integration
    return if company_id.present?

    self.company_id = calendar_event&.company_id || calendar_integration&.company_id
  end
end

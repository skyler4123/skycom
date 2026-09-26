class CalendarIntegration < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :calcom_event_type_id, :webhook_secret

  # --- Enums ---
  enum :status, { inactive: 0, active: 1, errored: 2 }, default: :inactive
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  encrypts :access_token, :refresh_token

  # --- Associations ---
  belongs_to :company
  belongs_to :accountable, polymorphic: true
  has_many :calendar_events, dependent: :destroy
  has_many :calendar_sync_mappings, dependent: :destroy

  # --- Validations ---
  validates :provider, presence: true
  validates :provider, uniqueness: { scope: [ :company_id, :accountable_type, :accountable_id ] }
end

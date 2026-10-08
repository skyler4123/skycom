class NotificationTag < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  has_many :notification_tag_appointments, dependent: :destroy
  has_many :notifications, through: :notification_tag_appointments
  has_many :employee_notification_tag_appointments, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }
end

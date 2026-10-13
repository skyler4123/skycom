class NotificationTag < ApplicationRecord
  attr_accessor :destroying_paired_for_role

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { system: 0, custom: 1 }

  # --- Associations ---
  belongs_to :company
  has_many :notification_tag_appointments, dependent: :destroy
  has_many :notifications, through: :notification_tag_appointments
  has_many :employee_notification_tag_appointments, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }

  before_destroy :prevent_destroy_if_system

  def destroy_paired_for_role!
    self.destroying_paired_for_role = true
    destroy!
  ensure
    self.destroying_paired_for_role = false
  end

  private

  def prevent_destroy_if_system
    return if destroying_paired_for_role
    return unless system?
    raise ActiveRecord::ReadOnlyRecord, "System notification tags cannot be deleted."
  end
end

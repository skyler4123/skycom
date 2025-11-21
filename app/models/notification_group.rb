class NotificationGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  # has_many :notification_group_appointments, dependent: :destroy # Can be added later

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  enum :business_type, {
    marketing: 0,
    transactional: 1,
    system_alerts: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end
class Notification < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :notification_group

  # --- Enums ---
  enum :status, {
    draft: 0,
    sent: 1,
    delivered: 2,
    failed: 3
  }

  enum :business_type, {
    email: 0,
    sms: 1,
    push_notification: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end

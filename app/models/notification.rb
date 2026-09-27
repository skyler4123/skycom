class Notification < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    email: 0,
    sms: 1,
    push_notification: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :notification_group
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_notification_appointments, dependent: :destroy
  has_many :employees, through: :employee_notification_appointments

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end

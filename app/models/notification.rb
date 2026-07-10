class Notification < ApplicationRecord
  attribute :metadata, :jsonb, array: true, default: []
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :notification_group
  belongs_to :category
  belongs_to :property_mapping

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    email: 0,
    sms: 1,
    push_notification: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end

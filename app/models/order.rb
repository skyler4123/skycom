class Order < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :invoices, dependent: :destroy
  has_many :order_appointments, dependent: :destroy
  has_many :products, through: :order_appointments, source: :appoint_to, source_type: "Product"
  has_many :services, through: :order_appointments, source: :appoint_to, source_type: "Service"


  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    online: 0,
    in_store: 1,
    phone: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :currency, presence: true

  validates :business_type, presence: true
end

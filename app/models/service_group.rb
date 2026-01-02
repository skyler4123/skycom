class ServiceGroup < ApplicationRecord
  include TagConcern
  include OrderConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :service_group_appointments, dependent: :destroy
  has_many :services, through: :service_group_appointments, source: :appoint_to, source_type: "Service"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    consulting: 0,
    maintenance: 1,
    support: 2,
    training: 3
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validates :business_type, presence: true
  validates :duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :start_at, presence: true
end

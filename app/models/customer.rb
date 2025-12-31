class Customer < ApplicationRecord
  include RoleConcern
  include AddressConcern

  # --- Associations ---
  belongs_to :user, optional: true
  belongs_to :company_group, optional: true
  belongs_to :company, optional: true

  has_many :orders, dependent: :destroy
  has_many :customer_group_appointments, as: :appoint_to, dependent: :destroy
  has_many :customer_groups, through: :customer_group_appointments

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

  has_many :customer_group_appointments, as: :appoint_to, dependent: :destroy
  has_many :customer_groups, through: :customer_group_appointments

  has_many :service_appointments, dependent: :destroy, as: :appoint_to
  has_many :services, through: :service_appointments

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS
  enum :business_type, {
    individual: 0,
    small_business: 1,
    enterprise: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end

class Customer < ApplicationRecord
  include RoleConcern

  # --- Associations ---
  belongs_to :user, optional: true
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
  # --- Enums ---
  enum :status, {
    active: 0,
    prospect: 1,
    inactive: 2
  }

  enum :business_type, {
    individual: 0,
    small_business: 1,
    enterprise: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end
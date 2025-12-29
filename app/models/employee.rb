class Employee < ApplicationRecord
  include RoleConcern
  include PermissionConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :user

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :service_appointments, dependent: :destroy, as: :appoint_to
  has_many :services, through: :service_appointments

  has_many :employee_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :employee_groups, through: :employee_group_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :bookings, as: :appoint_from, dependent: :destroy, class_name: "Booking"

  # --- Enums ---
  enum :business_type, {
    full_time: 0,
    part_time: 1,
    contractor: 2,
    intern: 3
  }
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  # --- Validations ---
  validates :name, presence: true
  validates :business_type, presence: true
end

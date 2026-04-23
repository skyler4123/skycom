# app/models/employee.rb

class Employee < ApplicationRecord
  include AddressConcern
  include RoleConcern
  include Employee::PermissionConcern
  include TagConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :user, optional: true


  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :service_appointments, dependent: :destroy, as: :appoint_to
  has_many :services, through: :service_appointments

  has_many :employee_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :employee_groups, through: :employee_group_appointments

  has_many :department_appointments, dependent: :destroy, as: :appoint_to
  has_many :departments, through: :department_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :bookings, as: :appoint_from, dependent: :destroy, class_name: "Booking"

  # --- Enums ---
  enum :business_type, {
    owner: 0,
    full_time: 1,
    part_time: 2,
    contractor: 3,
    intern: 4
  }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Validations ---
  validates :name, presence: true
  validates :business_type, presence: true
end

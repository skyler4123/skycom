class Facility < ApplicationRecord
  include TagConcern

  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :facility_group_appointments, as: :appoint_to, dependent: :destroy
  has_many :facility_groups, through: :facility_group_appointments
  has_many :bookings, as: :appoint_to, dependent: :destroy, class_name: "Booking"

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    publicly_traded: 0,
    privately_held: 1
  }

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
end

class Facility < ApplicationRecord
  belongs_to :company
  has_many :facility_group_appointments, as: :appoint_to, dependent: :destroy
  has_many :facility_groups, through: :facility_group_appointments
  has_many :bookings, as: :appoint_to, dependent: :destroy, class_name: "Booking"

  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }

  enum :business_type, { 
    publicly_traded: 0, 
    privately_held: 1 
  }

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true
  validates :business_type, presence: true
end

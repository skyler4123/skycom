class AttendancePolicy < ApplicationRecord
  belongs_to :company
  belongs_to :branch

  validates :latitude, :longitude, presence: true
end

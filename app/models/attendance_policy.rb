class AttendancePolicy < ApplicationRecord
  belongs_to :company
  belongs_to :branch

  enum :resolution_strategy, { paired: 0, check_in_only: 1 }, prefix: true, default: :paired

  validates :latitude, :longitude, presence: true
end

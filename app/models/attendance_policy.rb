class AttendancePolicy < ApplicationRecord
  belongs_to :company
  belongs_to :branch

  enum :resolution_strategy, {  check_in_only: 0, paired: 1 }, prefix: true, default: :check_in_only

  validates :latitude, :longitude, presence: true
end

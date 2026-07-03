class ShiftTemplate < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true

  validates :name, :start_time, :end_time, presence: true
end

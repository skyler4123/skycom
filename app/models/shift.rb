class Shift < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true

  validates :start_time, :end_time, presence: true
end

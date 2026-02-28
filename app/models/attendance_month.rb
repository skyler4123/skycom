class AttendanceMonth < ApplicationRecord
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer
  belongs_to :logable, polymorphic: true
  belongs_to :period
end

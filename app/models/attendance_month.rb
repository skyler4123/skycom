class AttendanceMonth < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :customer
  belongs_to :logable, polymorphic: true
  belongs_to :period
end

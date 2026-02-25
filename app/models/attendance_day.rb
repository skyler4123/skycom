class AttendanceDay < ApplicationRecord
  belongs_to :company_group
  belongs_to :branch, optional: true
  belongs_to :employee
  belongs_to :logable, polymorphic: true
  belongs_to :period
  belongs_to :approved_by
  belongs_to :edited_by
end

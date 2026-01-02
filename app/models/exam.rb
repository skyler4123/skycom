class Exam < ApplicationRecord
  include TagConcern

  belongs_to :exam_group
  belongs_to :company_group
  belongs_to :company, optional: true
end

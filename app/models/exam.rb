class Exam < ApplicationRecord
  belongs_to :exam_group
  belongs_to :company
end

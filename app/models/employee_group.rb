class EmployeeGroup < ApplicationRecord
  belongs_to :company

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

end

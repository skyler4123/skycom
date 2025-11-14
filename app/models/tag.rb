class Tag < ApplicationRecord
  belongs_to :company

  has_many :tag_appointments, dependent: :destroy
end

class Facility < ApplicationRecord
  belongs_to :company

  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }

  enum :business_type, { 
    publicly_traded: 0, 
    privately_held: 1 
  }

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true
  validates :business_type, presence: true
end

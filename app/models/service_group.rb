class ServiceGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  has_many :service_group_appointments, dependent: :destroy

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  enum :business_type, {
    consulting: 0,
    maintenance: 1,
    support: 2,
    training: 3
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
  validates :duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :start_at, presence: true
end
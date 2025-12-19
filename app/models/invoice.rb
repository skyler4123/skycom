class Invoice < ApplicationRecord
  # --- Associations ---
  belongs_to :order

  has_many :payments, dependent: :destroy

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    sales: 0,
    service: 1,
    subscription: 2
  }

  enum :currency, {
    usd: 0,
    eur: 1,
    gbp: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :currency, presence: true
  validates :number, presence: true, uniqueness: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :business_type, presence: true
end

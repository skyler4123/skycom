class Product < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :brand, optional: true

  has_many :order_appointments, as: :appoint_to, dependent: :destroy
  has_many :orders, through: :order_appointments

  has_many :product_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :product_groups, through: :product_group_appointments

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

  # --- Enums ---
  enum :status, {
    draft: 0,
    available: 1,
    discontinued: 2
  }

  enum :business_type, {
    physical: 0,
    digital: 1,
    service_based: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true

  include Product::ImageConcern
end

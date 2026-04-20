class ProductGroup < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern
  include OrderConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  has_many :product_group_appointments, dependent: :destroy
  has_many :products, through: :product_group_appointments, source: :appoint_to, source_type: "Product"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    category: 0,
    collection: 1,
    line: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end

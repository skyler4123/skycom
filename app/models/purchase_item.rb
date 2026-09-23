class PurchaseItem < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping
  # The Purchase ↔ Stock bridge: when set, purchase completion imports this
  # product into the purchase's destination warehouse (StockMovementService::
  # Purchases::CompleteService). Nil for non-stocked purchases.
  belongs_to :product, optional: true

  has_many :purchase_item_appointments, dependent: :destroy
  has_many :purchases, through: :purchase_item_appointments, source: :appoint_to, source_type: "Purchase"

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
end

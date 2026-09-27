class PurchasePurchaseItemAppointment < ApplicationRecord
  # Purchase line item — atomic row binding a Purchase to one PurchaseItem.
  #
  # Why it exists: carries the line economics
  # (quantity/unit_price/total_price); Purchase#total_price is always computed
  # live from these rows, never stored.
  # How to use: managed via nested line-item attributes on the Purchases
  # dashboard; read via `purchase.purchase_purchase_item_appointments`.
  # How it works: concrete FKs to company/purchase/purchase_item; company_id
  # derives via SetDefaultCompanyConcern with a same-company validation.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :purchase
  belongs_to :purchase_item
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

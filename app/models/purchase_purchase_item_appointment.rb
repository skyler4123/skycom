class PurchasePurchaseItemAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :purchase
  belongs_to :purchase_item
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

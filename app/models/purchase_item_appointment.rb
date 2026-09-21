class PurchaseItemAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :purchase_item
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  # --- Validations ---
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :same_company_as_purchase_item

  private

  def same_company_as_purchase_item
    return if purchase_item.nil? || appoint_to.nil?
    return if purchase_item.company_id == appoint_to.company_id

    errors.add(:appoint_to, "must belong to the same company as the purchase item")
  end
end

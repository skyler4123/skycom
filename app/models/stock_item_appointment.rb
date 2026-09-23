class StockItemAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :stock
  belongs_to :appoint_to, polymorphic: true

  # --- Validations ---
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  validate :same_company_as_stock_and_appoint_to

  private

  # NOTE: SetDefaultCompanyConcern derives the association name from the class
  # name ("StockItem" → :stock_item, which does not exist). The line item's
  # tenant resource is the :stock association, so we override the resolver.
  def find_resource_association
    stock
  end

  def same_company_as_stock_and_appoint_to
    errors.add(:stock, "must belong to the same company") if stock && stock.company_id != company_id
    return unless appoint_to && appoint_to.respond_to?(:company_id)

    errors.add(:appoint_to, "must belong to the same company") if appoint_to.company_id != company_id
  end
end

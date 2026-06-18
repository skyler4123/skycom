class Stock < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :product
  belongs_to :warehouse
  belongs_to :category
  belongs_to :property_mapping

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    inventory: 0,
    raw_material: 1,
    finished_good: 2,
    return: 3
  }
  validates :quantity, :reserved_quantity, presence: true, numericality: { only_integer: true }
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "already holds a tracking SKU row mapping for this layout" }

  kredis_integer :available_counter, key: ->(s) { "stock:#{s.id}:available" }

  after_save :sync_available_counter, if: -> { saved_change_to_quantity? || saved_change_to_reserved_quantity? }

  private

  def sync_available_counter
    available_counter.value = [ quantity - reserved_quantity, 0 ].max
  end
end

class Stock < ApplicationRecord
  before_validation :inherit_category_from_product, on: :create
  include PropertyMappingConcern
  validate :category_must_match_product_category
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  attribute :quantity, :integer, default: 0
  attribute :reorder, :integer, default: 0

  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

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
  validates :quantity, :reorder, presence: true, numericality: { only_integer: true }
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "already holds a tracking SKU row mapping for this layout" }

  kredis_integer :available_counter, key: ->(s) { "stock:#{s.id}:available" }

  after_save :sync_available_counter, if: -> { saved_change_to_quantity? || saved_change_to_reorder? }

  private

  def inherit_category_from_product
    return if category.present?
    self.category = product.category if product.present?
  end

  def category_must_match_product_category
    return unless category.present? && product.present?

    if category_id != product.category_id
      errors.add(:category, "must match product's category")
    end
  end

  def sync_available_counter
    available_counter.value = [ quantity - reorder, 0 ].max
  end
end

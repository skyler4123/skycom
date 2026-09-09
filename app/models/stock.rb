class Stock < ApplicationRecord
  # NOTE: must be declared before `include DynamicSearchConcern` — the meilisearch
  # settings block runs at include time. See the hook docs in the concern.
  def self.ms_extra_filterable_columns = %w[quantity pending] # rubocop:disable Layout/ClassStructure

  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern # rubocop:enable Layout/ClassStructure

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :quantity, :integer, default: 0
  attribute :pending, :integer, default: 0
  # --- Enums ---
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    inventory: 0,
    raw_material: 1,
    finished_good: 2,
    return: 3
  }
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true
  # Hot-path availability counter. Business code must go through the wrapper
  # methods below (available_count / reserve_stock! / release_reserved!) —
  # never the kredis proxy directly. See docs/KREDIS.md.
  kredis_counter :available_counter, key: ->(s) { "stock:#{s.id}:available" }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :product
  belongs_to :warehouse
  belongs_to :category
  belongs_to :property_mapping
  # --- Validations ---
  validates :quantity, :pending, presence: true, numericality: { only_integer: true }
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "already holds a tracking SKU row mapping for this layout" }

  after_save :sync_available_counter, if: -> { saved_change_to_quantity? || saved_change_to_pending? }

  # Returns sellable units from the hot counter; heals the counter from DB
  # columns when the key is missing (Redis restart/flush, bypassed writes).
  def available_count
    return available_counter.value if available_counter.exists?

    available_counter.increment(by: [ quantity - pending, 0 ].max)
  end

  # Atomically reserves qty sellable units (Redis decrement + DB promise).
  # Returns false — with both stores untouched — when stock is insufficient.
  def reserve_stock!(qty)
    qty = qty.to_i
    remaining = available_counter.decrement(by: qty)
    if remaining.negative?
      available_counter.increment(by: qty)
      return false
    end

    self.class.where(id: id).update_all([ "pending = pending + ?", qty ])
    true
  end

  # Rolls a reservation back: restores availability and consumes the promise.
  def release_reserved!(qty)
    qty = qty.to_i
    available_counter.increment(by: qty)
    self.class.where(id: id).update_all([ "pending = GREATEST(pending - ?, 0)", qty ])
  end

  private

  def sync_available_counter
    target = [ quantity - pending, 0 ].max
    delta = target - available_counter.value
    return if delta.zero?

    delta.positive? ? available_counter.increment(by: delta) : available_counter.decrement(by: -delta)
  end
end

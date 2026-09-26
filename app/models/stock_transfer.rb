# StockTransfer — Atomic purpose: the warehouse-to-warehouse movement document
# (warehouse → destination_warehouse, initiated_at / received_at). Receive writes
# a paired remove (source) + add (destination) StockTransaction
# (transaction_type: transfer); destination must differ from source.
class StockTransfer < ApplicationRecord
  # NOTE: must be declared before `include DynamicSearchConcern` — the meilisearch
  # settings block runs at include time. See the hook docs in the concern.
  def self.ms_extra_filterable_columns = %w[quantity] # rubocop:disable Layout/ClassStructure

  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern # rubocop:enable Layout/ClassStructure
  CODE_PREFIX = "STKTR".freeze
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    transfer: 0,
    adjustment: 1,
    return: 2,
    exchange: 3
  }
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :warehouse # source warehouse
  belongs_to :destination_warehouse, class_name: "Warehouse"
  belongs_to :product, optional: true
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  has_many :stock_transactions, as: :appoint_for, dependent: :restrict_with_error
  has_many :stock_item_appointments, as: :appoint_to, dependent: :destroy
  has_many :stocks, through: :stock_item_appointments


  validates :code, presence: true, uniqueness: true
  validates :destination_warehouse, comparison: { other_than: ->(transfer) { transfer.warehouse } },
    if: -> { warehouse.present? && destination_warehouse.present? }
end

class StockAdjustment < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  CODE_PREFIX = "STKAD".freeze
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  # --- Enums ---
  enum :direction, { increase: 0, decrease: 1 }

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :warehouse
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :appoint_by, polymorphic: true, optional: true

  has_many :stock_item_appointments, as: :appoint_to, dependent: :destroy
  has_many :stocks, through: :stock_item_appointments


  validates :code, presence: true, uniqueness: true
  validates :direction, presence: true
  validates :reason, length: { maximum: 500 }, allow_nil: true
end

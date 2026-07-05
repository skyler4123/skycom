class StockImport < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, default: {}
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :warehouse
  belongs_to :product
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    purchase: 0,
    return: 1,
    transfer_in: 2,
    adjustment: 3
  }
  # Documents connect directly to the logs they spawn via appoint_for anchor context
  has_many :stock_transactions, as: :appoint_for, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
end

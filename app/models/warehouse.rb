class Warehouse < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  attribute :metadata, :jsonb, array: true, default: []
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :address, optional: true
  has_many :stocks, dependent: :destroy

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    main: 0,
    distribution: 1,
    fulfillment: 2,
    cold_storage: 3
  }
end

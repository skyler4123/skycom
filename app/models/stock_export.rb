class StockExport < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
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
    sale: 0,
    transfer_out: 1,
    return_to_supplier: 2,
    adjustment: 3,
    damaged: 4,
    expired: 5
  }
end

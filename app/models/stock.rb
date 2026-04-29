class Stock < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :warehouse
  belongs_to :category, optional: true

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    inventory: 0,
    raw_material: 1,
    finished_good: 2,
    return: 3
  }
end
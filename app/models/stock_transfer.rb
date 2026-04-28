class StockTransfer < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :product
  belongs_to :category, optional: true
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true, optional: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true
end
class Inventory < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
end

class OrderGroup < ApplicationRecord
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
  belongs_to :customer
  belongs_to :category
  belongs_to :property_mapping
end

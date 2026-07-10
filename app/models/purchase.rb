class Purchase < ApplicationRecord
  attribute :metadata, :jsonb, array: true, default: []
  attribute :currency_code, :integer, default: 840
  attribute :country_code, :integer, default: 1
  attribute :timezone, :string, default: "UTC"

  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
end

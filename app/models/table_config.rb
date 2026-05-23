class TableConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :visible_fields, :jsonb, default: [ "name" ]

  belongs_to :company
  belongs_to :category, optional: true
end

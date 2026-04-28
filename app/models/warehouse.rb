class Warehouse < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category, optional: true
  belongs_to :address, optional: true
  has_many :stocks, dependent: :destroy
end
class OrderGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_order_group_appointments, dependent: :destroy
  has_many :employees, through: :employee_order_group_appointments
end

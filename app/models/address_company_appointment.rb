class AddressCompanyAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true
  enum :business_type, { office: 0, home: 1, billing: 2, shipping: 3 }
  belongs_to :address
  belongs_to :company
end

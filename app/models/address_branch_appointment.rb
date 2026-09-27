class AddressBranchAppointment < ApplicationRecord
  # Address link — atomic pairwise row binding one Address to its owner record.
  #
  # Why it exists: addresses are shared, immutable rows (see Address); this table
  # records WHICH address an owner uses and in WHAT capacity (business_type),
  # replacing the old polymorphic address_appointments table.
  # How to use: never create rows directly — call `record.attach_address(**attrs)`
  # (see AddressConcern); read via `record.address` (current) / `record.addresses`.
  # How it works: company_id derives from the owner via SetDefaultCompanyConcern;
  # re-attaching archives the previous active row instead of deleting it,
  # preserving address history.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true
  enum :business_type, { office: 0, home: 1, billing: 2, shipping: 3 }
  belongs_to :company, optional: true
  belongs_to :address
  belongs_to :branch
end

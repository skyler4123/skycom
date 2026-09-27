class CustomerMembershipAppointment < ApplicationRecord
  # Customer entitlement link — atomic row attaching a Membership/Reservation.
  #
  # Why it exists: a customer can hold concurrent entitlements per business_type
  # (e.g. loyalty Gold AND subscription Pro); this table versions them.
  # How to use: call `customer.attach_membership(code, business_type:)`
  # (see MembershipConcern); read via `customer.membership` / `membership_of_type`.
  # How it works: attaching archives only the active row of the SAME
  # business_type, leaving other tracks untouched. company_id derives from the
  # customer via SetDefaultCompanyConcern.
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, { active: 0, archived: 1 }, prefix: true
  enum :workflow_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true
  enum :business_type, { primary: 0, loyalty: 1, subscription: 2, segment: 3 }
  belongs_to :company
  belongs_to :customer
  belongs_to :membership
end

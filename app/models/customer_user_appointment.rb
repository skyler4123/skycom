# frozen_string_literal: true

# CustomerUserAppointment — Atomic purpose: grants one platform User sign-in access to one Customer record in the B2B portal.
#
# Why it exists: the existing Users are company owners and staff; a wholesale buyer is none of those. Without an explicit link, a buyer logging in either sees the company back office or nothing.
# How it works: atomic pair between Customer and User, with a portal role so an approver and a purchase clerk differ. Invitation and acceptance timestamps make pending invites distinguishable from active accounts. Company derives from the customer.
# Main associations: belongs_to :company, :customer, :user.
class CustomerUserAppointment < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :role, PORTAL_ROLES, prefix: true, default: :viewer

  # --- Associations ---
  belongs_to :company
  belongs_to :customer
  belongs_to :user

  # --- Scopes ---
  scope :active, -> { where(revoked_at: nil) }

  # --- Validations ---
  validates :user_id, uniqueness: { scope: :customer_id }

  # --- Methods ---
  def active?
    revoked_at.nil?
  end
end

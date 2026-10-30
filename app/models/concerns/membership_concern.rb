# frozen_string_literal: true

# MembershipConcern — Atomic purpose: versioned customer entitlement links to
# Membership rows through CustomerMembershipAppointment.
#
# Why it exists: a customer can hold concurrent entitlements per business_type
# (loyalty, subscription, segment) and history must be preserved, so attaching a
# new membership archives only the active row of the same type.
# How it works: attach_membership finds-or-creates the company-scoped Membership,
# archives the previous active appointment of the same business_type, and creates
# the new row; readers expose current and per-type memberships.
# Main associations: none directly; adds has_many
# :customer_membership_appointments and :memberships through them to Customer.

#
# == Purpose:
# Gives a Customer concurrent, versioned links to Membership rows through the
# atomic CustomerMembershipAppointment table — one active track per
# business_type (e.g. loyalty Gold AND subscription Pro at once).
#
# == How It Works:
# 1. attach_membership finds the Membership by code, archives ONLY the active
#    rows of the SAME business_type (other tracks survive), creates the new row
#    as :active, and touches the customer for cache invalidation.
# 2. Readers (membership, membership_of_type) resolve through the latest
#    active appointment and are Rails.sync_cache-cached per customer version.
# 3. company_id on new rows derives from the customer via
#    SetDefaultCompanyConcern.
#
# == Usage:
# Include in Customer; call customer.attach_membership(code, business_type:)
# or assign customer.membership = code; read customer.membership /
# customer.membership_of_type(type). Never create atomic rows directly.
#
# == Example:
#   customer = Customer.find(id)
#   # 1. Set Loyalty Tier
#   customer.attach_membership("gold_tier", business_type: :loyalty)
#   # 2. Set Subscription Track (does NOT archive the Loyalty Tier)
#   customer.attach_membership("pro_plan", business_type: :subscription)
#   # 3. Retrieve specific memberships
#   customer.membership_of_type(:loyalty)      # => <Membership: Gold>
#   customer.membership_of_type(:subscription) # => <Membership: Pro>
#   # 4. Default getter (the most recently attached)
#   customer.membership # => <Membership: Pro>
#

module MembershipConcern
  extend ActiveSupport::Concern

  included do
    has_many :customer_membership_appointments, foreign_key: :customer_id, dependent: :destroy

    # All memberships ever held
    has_many :memberships, through: :customer_membership_appointments, source: :membership

    # Current appointments for all business types
    has_many :current_customer_membership_appointments, -> {
               where(lifecycle_status: :active)
             },
             foreign_key: :customer_id,
             class_name: "CustomerMembershipAppointment"

    # Quick access to the most recent active membership
    has_one :latest_customer_membership_appointment, -> {
              where(lifecycle_status: :active)
              .order(created_at: :desc)
            },
            foreign_key: :customer_id,
            class_name: "CustomerMembershipAppointment"

    has_one :db_membership, through: :latest_customer_membership_appointment, source: :membership
  end

  # Getter: Returns the most recent active Membership
  def membership
    Rails.sync_cache.fetch(
      CacheKeyService.customer_current_membership(self),
      expires_in: CACHE_DEFAULT_EXPIRY
    ) { db_membership }
  end

  # Setter: Defaults to :primary if no context is given
  def membership=(code)
    return if code.blank?
    attach_membership(code)
  end

  def attach_membership(code, business_type: :primary, **options)
    target_membership = Membership.find_by!(code: code)

    transaction do
      # 1. Archive ONLY the old membership of the SAME business_type
      # This allows a customer to be "Gold" (loyalty) AND "Pro" (subscription)
      customer_membership_appointments.where(business_type: business_type)
                                      .where(lifecycle_status: :active)
                                      .update_all(lifecycle_status: CustomerMembershipAppointment.lifecycle_statuses[:archived])

      # 2. Create the new appointment
      customer_membership_appointments.create!(
        membership: target_membership,
        business_type: business_type,
        lifecycle_status: :active,
        workflow_status: options[:workflow_status] || :approved
      )

      # 3. Cache Invalidation
      touch if persisted?
    end
  end

  # Helper to get membership by specific type
  def membership_of_type(type)
    Rails.sync_cache.fetch(
      CacheKeyService.customer_membership_of_type(self, type),
      expires_in: CACHE_DEFAULT_EXPIRY
    ) do
      customer_membership_appointments.where(lifecycle_status: :active, business_type: type)
                                      .first&.membership
    end
  end
end

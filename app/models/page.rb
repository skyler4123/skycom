# frozen_string_literal: true

# Page — Atomic purpose: one deployable operating-page definition for a
# company/branch, targeting a business role and screen resolution.
#
# Why it exists: the platform ships role-specific POS and back-office screens;
# this row selects which page variant a branch uses for a given target_role and
# target_resolution (see docs/HOMEPAGE.md).
# How it works: belongs to a company and branch and carries business_type,
# target_role, target_resolution, lifecycle_status, and workflow_status. The
# branch + role + resolution + code combination is unique, and the frontend
# loads the active/deployed page for the current context.
# Main associations: belongs_to :company, :branch (both required).
class Page < ApplicationRecord
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :business_type, {
    retail: 10,
    restaurant: 20,
    hospital: 30,
    education: 40
  }, prefix: true, default: :retail
  # Unified target role mapping
  enum :target_role, {
    # Retail Roles
    retail_cashier: 110,
    retail_store_manager: 120,

    # Restaurant Roles
    restaurant_cashier: 210,
    restaurant_waiter: 220,
    restaurant_kitchen_staff: 230,

    # Hospital Roles
    hospital_receptionist: 310,
    hospital_doctor: 320,
    hospital_nurse: 330
  }, default: :retail_cashier
  enum :target_resolution, {
    mobile_portrait: 10,    # Waiter taking orders at a table
    tablet_landscape: 20,   # Quick-service restaurant counter or hotel check-in
    desktop_widescreen: 30  # Heavy-duty Retail POS or Hospital Receptionist board
  }, prefix: true, default: :desktop_widescreen
  enum :lifecycle_status, { active: 10, draft: 20, archived: 30 }, prefix: true, default: :draft
  enum :workflow_status, { pending_review: 10, approved: 20, deployed: 30 }, prefix: true, default: :pending_review
  belongs_to :company
  belongs_to :branch
end

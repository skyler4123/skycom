# frozen_string_literal: true

# Page — Atomic purpose: one deployable operating-page definition for a
# company/branch, targeting a business role and screen resolution.
#
# Why it exists: the platform ships role-specific POS and back-office screens;
# this row selects which page variant a branch uses for a given target_role and
# target_resolution (see docs/OPERATING_PAGES.md).
# How it works: belongs to a company and branch and carries business_type,
# target_role, target_resolution, lifecycle_status, and workflow_status. The
# company's business_type decides which page types are available, and each page
# type has one record per resolution. The branch + role + resolution combination
# is unique, and the frontend loads the active/deployed page for the current
# context. Names carry a Mobile/Desktop suffix so the two variants are distinct.
# Main associations: belongs_to :company, :branch (both required).
class Page < ApplicationRecord
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  enum :business_type, {
    retail: 10,
    restaurant: 20,
    hospital: 30,
    education: 40,
    hotel: 50,
    fitness: 60
  }, prefix: true
  # Unified target role mapping, grouped by business type.
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
    hospital_nurse: 330,

    # Education Roles
    education_receptionist: 410,
    education_teacher: 420,
    education_manager: 430,

    # Hotel Roles
    hotel_receptionist: 510,
    hotel_housekeeping: 520,
    hotel_manager: 530,

    # Fitness Roles
    fitness_receptionist: 610,
    fitness_trainer: 620,
    fitness_manager: 630
  }
  enum :target_resolution, {
    mobile: 10,   # Phones and tablets
    desktop: 20   # Desktop browsers
  }, prefix: true, default: :desktop
  enum :lifecycle_status, { active: 10, draft: 20, archived: 30 }, prefix: true, default: :draft
  enum :workflow_status, { pending_review: 10, approved: 20, deployed: 30 }, prefix: true, default: :pending_review

  belongs_to :company
  belongs_to :branch

  validates :name, :business_type, :target_role, :target_resolution, presence: true
  validates :target_role, uniqueness: { scope: %i[branch_id target_resolution] }
  validate :business_type_matches_company
  validate :branch_belongs_to_company
  validate :target_role_in_catalog

  before_validation :assign_business_type_from_company
  before_validation :assign_default_name_from_catalog
  before_validation :ensure_name_resolution_suffix

  def self.catalog_for(business_type)
    PAGE_CATALOG.fetch(business_type&.to_sym, [])
  end

  def self.catalog_entry(business_type:, target_role:)
    catalog_for(business_type).find { |entry| entry[:target_role] == target_role&.to_sym }
  end

  def self.target_roles_for(business_type)
    catalog_for(business_type).map { |entry| entry[:target_role] }
  end

  def self.label_for(business_type:, target_role:)
    catalog_entry(business_type:, target_role:)&.dig(:name)
  end

  def self.default_name_for(business_type:, target_role:, target_resolution:)
    entry = catalog_entry(business_type:, target_role:)
    return if entry.blank? || target_resolution.blank?

    "#{entry[:name]} #{target_resolution.to_s.humanize}"
  end

  def self.implemented?(business_type:, target_role:, target_resolution:)
    entry = catalog_entry(business_type:, target_role:)
    return false if entry.blank? || target_resolution.blank?

    Array(entry[:implemented]).map(&:to_sym).include?(target_resolution.to_sym)
  end

  def placeholder?
    !self.class.implemented?(
      business_type: business_type,
      target_role: target_role,
      target_resolution: target_resolution
    )
  end

  private

  def assign_business_type_from_company
    return if business_type.present? || company.blank?
    return unless self.class.business_types.key?(company.business_type)

    self.business_type = company.business_type
  end

  def assign_default_name_from_catalog
    return if name.present?

    self.name = self.class.default_name_for(
      business_type: business_type,
      target_role: target_role,
      target_resolution: target_resolution
    )
  end

  def ensure_name_resolution_suffix
    return if name.blank? || target_resolution.blank?

    base_name = name.to_s.sub(/\s+(Mobile|Desktop)\z/i, "").strip
    return if base_name.blank?

    self.name = "#{base_name} #{target_resolution.to_s.humanize}"
  end

  def business_type_matches_company
    return if company.blank? || business_type.blank? || business_type == company.business_type

    errors.add(:business_type, "must match the company's business type")
  end

  def branch_belongs_to_company
    return if branch.blank? || company.blank? || branch.company_id == company_id

    errors.add(:branch, "must belong to the company")
  end

  def target_role_in_catalog
    return if business_type.blank? || target_role.blank?
    return if self.class.target_roles_for(business_type).include?(target_role.to_sym)

    errors.add(:target_role, "is not available for this business type")
  end
end

# frozen_string_literal: true

# System — Atomic purpose: the platform's singleton system record that provisions
# and owns the dedicated system company.
#
# Why it exists: Skycom itself needs a tenant for platform-level data (a
# super-admin user and company); the System row's identity is immutable and it can
# never be destroyed (see docs/SYSTEM_COMPANY.md).
# How it works: before_create ensure_company! creates or heals the system User and
# Company (skipping business-type seeding via Company#system_owned); identity
# changes and destruction are blocked. The country enum adds a non-ISO `global`
# value without leaking into COUNTRY_CODES.
# Main associations: belongs_to :company (optional until ensure_company! creates
# it); SYSTEM_COMPANY_COUNTRIES/SYSTEM_COMPANY_CURRENCIES map the platform
# country/currency to Company enums.
class System < ApplicationRecord
  # NOTE: single-file country enum — adds a non-ISO `global` scope without
  # leaking into the shared COUNTRY_CODES used by every other model.
  SYSTEM_COUNTRY_CODES = { global: 0, us: 840, vn: 704 }.freeze

  # Country/currency used for the auto-created system company
  # (System#ensure_company!). Keys are strings (enum readers return strings).
  # The country map covers the non-ISO `global` (mapped to the platform
  # default, US) because Company.country (COUNTRY_CODES) has no :global value;
  # the currency map is 1:1 (System currency uses the shared CURRENCIE_CODES).
  # An unmapped/nil value falls back to the Company enum defaults (us/usd)
  # via the nil-safe [] lookup.
  SYSTEM_COMPANY_COUNTRIES = { "global" => :us, "us" => :us, "vn" => :vn }.freeze
  SYSTEM_COMPANY_CURRENCIES = { "usd" => :usd, "vnd" => :vnd }.freeze

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :name, :string, default: "System"
  attribute :balance_cents, :integer, default: 0
  attribute :active, :boolean, default: true

  # --- Enums ---
  enum :country, SYSTEM_COUNTRY_CODES, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true

  # --- Associations ---
  belongs_to :company, optional: true

  # --- Validations ---
  validates :code, presence: true, uniqueness: true

  # 1. UPDATE Security: Critical identity fields cannot be changed
  validate :prevent_identity_changes, on: :update

  # 2. DESTROY Security: The System record can never be deleted
  before_create :ensure_company!
  before_destroy :prevent_destruction

  # Creates (or heals) the dedicated system company: a super_admin user
  # (email derived from the unique code) plus a Company with owner records,
  # wallet, and default setting — business-type seeding is skipped via the
  # Company#system_owned creation flag. Idempotent; also used by the seed
  # to repair links wiped during reseeding.
  def ensure_company!
    return company if company.present?

    user = find_or_create_system_user!
    company = Company.new(
      user: user,
      name: name,
      description: "Skycom platform system company",
      business_type: :system,
      lifecycle_status: :active,
      workflow_status: :active,
      country: SYSTEM_COMPANY_COUNTRIES[country] || :us,
      currency: SYSTEM_COMPANY_CURRENCIES[currency] || :usd
    ).tap { |c| c.system_owned = true }
    company.save!
    # Assign AFTER the save — assigning an unsaved belongs_to target would
    # snapshot company_id as nil. During creation the INSERT persists the FK;
    # on the heal path (already-persisted System) write it explicitly.
    self.company = company
    update_column(:company_id, company.id) unless new_record?
  end

  private

  def find_or_create_system_user!
    User.find_or_create_by!(email: "#{code}@system.com") do |u|
      u.name = name
      u.password = SecureRandom.hex(16)
      u.system_role = :super_admin
      u.verified = true
    end
  end

  # --- Security Logic ---

  def prevent_identity_changes
    # If the user tries to change the code, block it.
    if code_changed?
      errors.add(:code, "cannot be changed once created.")
    end

    # If the user tries to change the name, block it.
    if name_changed?
      errors.add(:name, "cannot be changed once created.")
    end
  end

  def prevent_destruction
    errors.add(:base, "The System record is permanent and cannot be deleted.")
    throw :abort # This is required to strictly stop the deletion in Rails
  end
end

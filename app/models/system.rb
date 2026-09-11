# app/models/system.rb
class System < ApplicationRecord
  # Single-file country enum: adds a non-ISO `global` scope without leaking
  # into the shared COUNTRY_CODES used by every other model.
  SYSTEM_COUNTRY_CODES = { global: 0, us: 840, vn: 704 }.freeze

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :name, :string, default: "System"
  attribute :balance_cents, :integer, default: 0
  attribute :active, :boolean, default: true

  # --- Enums ---
  enum :country, SYSTEM_COUNTRY_CODES, prefix: true
  enum :currency, CURRENCIE_CODES, prefix: true

  # --- Associations ---
  # --- Validations ---
  validates :code, presence: true, uniqueness: true

  # 1. UPDATE Security: Critical identity fields cannot be changed
  validate :prevent_identity_changes, on: :update

  # 2. DESTROY Security: The System record can never be deleted
  before_destroy :prevent_destruction

  private

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

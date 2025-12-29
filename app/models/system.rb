# app/models/system.rb
class System < ApplicationRecord
  # --- Associations ---
  has_many :subscription_appointments, as: :appoint_from
  has_many :subscriptions, through: :subscription_appointments

  # --- Validations ---
  validates :code, presence: true, uniqueness: true

  # 1. CREATE Security: Only one System can ever exist
  validate :ensure_singleton, on: :create

  # 2. UPDATE Security: Critical identity fields cannot be changed
  validate :prevent_identity_changes, on: :update

  # 3. DESTROY Security: The System record can never be deleted
  before_destroy :prevent_destruction

  private

  # --- Security Logic ---

  def ensure_singleton
    if System.exists?
      errors.add(:base, "There can be only one System.")
    end
  end

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

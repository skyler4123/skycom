class PaymentMethodAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :payment_method
  belongs_to :company

  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true, optional: true
  belongs_to :appoint_by, polymorphic: true, optional: true

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    online: 0,
    in_store: 1,
    recurring: 2
  }

  # --- Scopes ---
  scope :company_level, -> { where(appoint_to_type: "Company") }
  scope :branch_level, -> { where(appoint_to_type: "Branch") }

  # --- Callbacks ---
  before_validation :default_appoint_to_to_company
  after_update :cascade_lifecycle_to_branch_appointments, if: :company_level_lifecycle_change?

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id, message: "This payment method code is already assigned to this company group." }

  validates :business_type, presence: true

  validate :payment_method_country_matches_company
  validate :payment_method_must_be_active_in_company

  private

  def default_appoint_to_to_company
    self.appoint_to ||= company if company.present?
  end

  def payment_method_country_matches_company
    return unless payment_method && company
    return if payment_method.country_before_type_cast == company.country_before_type_cast

    errors.add(:payment_method, "country (#{payment_method.country_before_type_cast}) does not match company country (#{company.country_before_type_cast})")
  end

  def payment_method_must_be_active_in_company
    return unless appoint_to_type == "Branch"
    return if PaymentMethodAppointment.company_level
      .where(company_id: company_id, payment_method_id: payment_method_id)
      .exists?(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))

    errors.add(:appoint_to, "payment method is not active at the company level")
  end

  def company_level_lifecycle_change?
    persisted? && appoint_to_type == "Company" && saved_change_to_lifecycle_status?
  end

  def cascade_lifecycle_to_branch_appointments
    PaymentMethodAppointment.branch_level
      .where(company_id: company_id, payment_method_id: payment_method_id)
      .update_all(lifecycle_status: lifecycle_status)
  end

  # Overrides SetDefaultCompanyConcern#set_default_company_from_resource.
  # Derives company_id from the polymorphic appoint_to (Company or Branch).
  def set_default_company_from_resource
    return if company.present?
    return if company_id.present?

    case appoint_to
    when Company
      self.company_id = appoint_to.id
    when Branch
      self.company_id = appoint_to.company_id
    end
  end
end

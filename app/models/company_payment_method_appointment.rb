class CompanyPaymentMethodAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { online: 0, in_store: 1, recurring: 2 }
  belongs_to :company
  belongs_to :payment_method
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id, message: "This payment method code is already assigned to this company group." }
  validates :business_type, presence: true
  validate :payment_method_country_matches_company

  after_update :cascade_lifecycle_to_branch_appointments, if: :saved_change_to_lifecycle_status?

  private

  def payment_method_country_matches_company
    return unless payment_method && company
    return if payment_method.country_before_type_cast == company.country_before_type_cast

    errors.add(:payment_method, "country (#{payment_method.country_before_type_cast}) does not match company country (#{company.country_before_type_cast})")
  end

  def cascade_lifecycle_to_branch_appointments
    BranchPaymentMethodAppointment
      .where(company_id: company_id, payment_method_id: payment_method_id)
      .update_all(lifecycle_status: lifecycle_status)
  end
end

class BranchPaymentMethodAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, { online: 0, in_store: 1, recurring: 2 }
  belongs_to :company
  belongs_to :branch
  belongs_to :payment_method
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id, message: "This payment method code is already assigned to this company group." }
  validates :business_type, presence: true
  validate :payment_method_country_matches_company
  validate :payment_method_must_be_active_in_company
  validate :branch_must_belong_to_company

  private

  def payment_method_country_matches_company
    return unless payment_method && company
    return if payment_method.country_before_type_cast == company.country_before_type_cast

    errors.add(:payment_method, "country (#{payment_method.country_before_type_cast}) does not match company country (#{company.country_before_type_cast})")
  end

  def payment_method_must_be_active_in_company
    return unless company_id && payment_method_id
    return if CompanyPaymentMethodAppointment
      .where(company_id: company_id, payment_method_id: payment_method_id)
      .exists?(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))

    errors.add(:branch, "payment method is not active at the company level")
  end

  def branch_must_belong_to_company
    return unless branch && company_id
    return if branch.company_id == company_id

    errors.add(:branch, "does not belong to this company")
  end
end

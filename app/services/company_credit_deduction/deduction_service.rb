# frozen_string_literal: true

# CompanyCreditDeduction::DeductionService — the public credit-deduction API.
#
# Call it from any layer when a feature consumes credits:
#
#   CompanyCreditDeduction::DeductionService.call(
#     company: company,
#     amount: 3,
#     action_type: "access_pos_console",
#     description: "POS console access"
#   )
#
# Suspended companies are skipped by default. A job or mailer that must charge
# while the company is suspended passes `allow_suspended: true` explicitly.
#
# `external_id:` is an optional retry key. A repeated call with the same key
# finds the earlier debit wallet log and returns false without charging again.
class CompanyCreditDeduction::DeductionService < CompanyCreditDeduction::BaseService
  def initialize(company:, amount:, action_type:, description: nil,
    source: nil, allow_suspended: false, external_id: nil)
    super(company: company)
    @amount = amount
    @action_type = action_type.to_s
    @description = description.presence || @action_type.tr("_", " ")
    @source = source
    @allow_suspended = allow_suspended
    @external_id = external_id

    unless CREDIT_DEDUCTION_ACTION_TYPES.include?(@action_type)
      raise ArgumentError, "unknown credit action_type: #{@action_type}"
    end
  end

  def call
    return false if @company.blank?
    return false unless @amount.is_a?(Integer) && @amount.positive?
    return false if !@allow_suspended && @company.suspended?
    return false if duplicate_charge?

    super
  end

  private

  def action_type = @action_type
  def description = @description
  def cost = @amount
  def source = @source || @company
  def external_id = @external_id

  def duplicate_charge?
    return false if @external_id.blank?

    wallet = @company.company_wallet
    return false unless wallet

    wallet.company_wallet_logs
      .where(change_type: :debit, external_id: @external_id)
      .exists?
  end
end

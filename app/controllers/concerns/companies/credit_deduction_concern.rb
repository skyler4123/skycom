# frozen_string_literal: true

# Credit deduction is priced per page in CREDIT_DEDUCTION_RATES and charged
# from this concern. The deduction math lives in
# CompanyCreditDeduction::DeductionService; this concern only decides WHEN.
#
# Default flow (:first_json):
#   1. A successful HTML page request mints a signed page token into the body.
#      The HTML shell itself is free.
#   2. The first successful JSON request for the same controller#action claims
#      the token atomically and charges once.
#   3. Later JSON requests with that token are free (polling, period changes,
#      sub-resources). A new page load mints a new token and charges again.
#
# :html          — charge the successful HTML page request (available for later).
# :every_request — charge every successful JSON request (available for API use).
# :none          — never charge.
#
# Deduction failures are rescued so a billing problem never breaks the request.
module Companies::CreditDeductionConcern
  extend ActiveSupport::Concern

  included do
    before_action :mint_credit_page_token, if: :credit_page_html_request?
    after_action :run_credit_deduction
  end

  private

  def mint_credit_page_token
    return unless current_company && current_employee
    return unless credit_page_rule&.dig(:charge_on) == :first_json

    @credit_page_token = CompanyCreditDeduction::PageTokenService.generate(
      page: credit_page_key,
      company: current_company,
      employee: current_employee
    )
  end

  def run_credit_deduction
    return unless performed? && response.successful?

    rule = credit_page_rule
    return unless rule

    case rule[:charge_on]
    when :html
      deduct_page_credits(rule) if credit_page_html_request?
    when :first_json
      deduct_first_json_page_credits(rule) if request.format.json?
    when :every_request
      deduct_page_credits(rule) if request.format.json?
    end
  rescue StandardError => e
    # A deduction failure must never break the request — log and continue.
    Rails.logger.warn("[CompanyCreditDeduction] #{self.class}##{action_name}: #{e.message}")
  end

  def deduct_first_json_page_credits(rule)
    token = request.headers[CompanyCreditDeduction::PageTokenService::HEADER]
    payload = CompanyCreditDeduction::PageTokenService.verify(token)
    return unless payload
    return unless payload["page"] == credit_page_key
    return unless payload["company_id"].to_s == current_company.id.to_s
    return unless payload["employee_id"].to_s == current_employee&.id.to_s
    return unless current_company.claim_credit_page_token!(token)

    begin
      deduct_page_credits(rule)
    rescue StandardError
      current_company.release_credit_page_token!(token)
      raise
    end
  end

  def deduct_page_credits(rule)
    CompanyCreditDeduction::DeductionService.call(
      company: current_company,
      amount: rule[:cost],
      action_type: rule[:action_type],
      description: rule[:description],
      allow_suspended: false
    )
  end

  def credit_page_rule
    CREDIT_DEDUCTION_RATES[credit_page_key]
  end

  # Mobile shells hydrate from the web JSON endpoint, so the mobile controller
  # path maps onto the same page rule by dropping the "mobile/" prefix.
  def credit_page_key
    "#{controller_path.sub(%r{\Amobile/}, "")}##{action_name}"
  end

  def credit_page_html_request?
    request.get? && request.format.html?
  end
end

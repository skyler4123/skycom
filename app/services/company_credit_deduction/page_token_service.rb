# frozen_string_literal: true

# CompanyCreditDeduction::PageTokenService — signs and verifies the one-time
# token minted by a billable HTML page load.
#
# The token is not a charge. It proves that the browser loaded a specific page
# (controller#action) for a specific company/employee and expires after
# CREDIT_PAGE_TOKEN_TTL. The first successful JSON request for that page claims
# it; the controller concern then charges once.
module CompanyCreditDeduction
  class PageTokenService
    PURPOSE = "credit_page_token"
    HEADER = "X-Credit-Page-Token"

    def self.generate(page:, company:, employee:)
      verifier.generate(
        {
          page: page.to_s,
          company_id: company.id,
          employee_id: employee.id,
          nonce: SecureRandom.uuid
        },
        expires_in: CREDIT_PAGE_TOKEN_TTL,
        purpose: PURPOSE
      )
    end

    def self.verify(token)
      return if token.blank?

      verifier.verified(token, purpose: PURPOSE)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def self.verifier
      Rails.application.message_verifier(PURPOSE)
    end
  end
end

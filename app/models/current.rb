class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true

  # ------------------------------------------------------------------------
  attribute :company_id

  # company_owner is User
  def self.company_owner
    Current.user&.company_owner
  end

  def self.companies
    company_owner&.companies
  end

  def self.company
    Company.find(company_id) if company_id.present?
  end

  def self.branches
    company&.branches
  end
  # ------------------------------------------------------------------------
end

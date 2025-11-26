class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true


  # ------------------------------------------------------------------------
  def self.company_owner
    Current.user&.company_owner
  end

  def self.companies
    company_owner&.companies
  end
end

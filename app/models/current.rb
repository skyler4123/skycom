class Current < ActiveSupport::CurrentAttributes
  attribute :session_id, :user_id, :user_agent, :ip_address
  attribute :company_id

  def session
    return nil unless session_id.present?
    @session ||= Session.find_by(id: session_id)
  end

  def user
    return nil unless user_id.present?
    @user ||= User.find_by(id: user_id)
  end

  # company_owner is User
  def self.company_owner
    Current.user&.company_owner
  end

  def self.companies
    company_owner&.companies
  end

  def self.company
    # IMPORTANT: Memoize the company object too!
    # Otherwise, Current.company.branches calls Company.find(id) every time.
    @company ||= Company.find(company_id) if company_id.present?
  end

  def self.branches
    company&.branches
  end
  # ------------------------------------------------------------------------
end

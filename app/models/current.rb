class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true

  # ------------------------------------------------------------------------
  attribute :company_group_business_type  
  attribute :company_group

  # company_owner is User
  def self.company_owner
    Current.user&.company_owner
  end

  def self.company_groups
    company_owner&.company_groups
  end

  def self.company_group
    company_groups.first
  end

  def self.companies
    company_group&.companies
  end
  # ------------------------------------------------------------------------

end

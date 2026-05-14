class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true

  # ------------------------------------------------------------------------
  attribute :company_id
  attribute :cached_versions_store

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

  def self.cached_version
    # Use the attribute to memoize within the request
    self.cached_versions_store ||= company.cached_version.attributes
  end
  # ------------------------------------------------------------------------
end

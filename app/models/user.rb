class User < ApplicationRecord
  # --- Concerns ---
  # Includes functionality for handling user avatars, likely from `app/models/user/avatar_concern.rb`.
  include User::CacheConcern
  include User::AvatarConcern
  include User::ChatImagesConcern
  include AddressConcern
  include User::OmniauthConcern
  include User::RetailConcern
  include User::SearchConcern

  USER_CACHE_EXPIRY = 5.minutes
  EMAIL_VERIFICATION_TOKEN_EXPIRY = 2.days
  PASSWORD_RESET_TOKEN_EXPIRY = 20.minutes

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :verified, :boolean, default: false

  normalizes :email, with: -> { _1.strip.downcase }
  enum :system_role, {
    super_admin: 0,
    admin: 1,
    company_owner: 2,
    company_employee: 3,
    company_customer: 4
  }, prefix: true
  enum :country, COUNTRY_CODES, prefix: true, default: :us
  has_secure_password

  generates_token_for :email_verification, expires_in: EMAIL_VERIFICATION_TOKEN_EXPIRY do
    email
  end

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_TOKEN_EXPIRY do
    password_salt.last(10)
  end

  has_many :sessions, dependent: :destroy
  has_many :sign_in_tokens, dependent: :destroy

  has_many :companies, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :customers, dependent: :destroy
  belongs_to :parent_user, class_name: "User", optional: true
  has_many :child_users, class_name: "User", foreign_key: "parent_user_id", dependent: :destroy
  has_many :assigned_company_tickets, class_name: "CompanyTicket",
           foreign_key: :assigned_user_id, dependent: :nullify
  # restrict: staff replies must survive staff cleanup (first_responded_at
  # points at them). Soft flows are unaffected.
  has_many :company_ticket_comments, as: :author, dependent: :restrict_with_error
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  # ----------------------------------------------------------------------------------------------------
  validates :name, uniqueness: true, allow_blank: true

  after_commit :refresh_cache, on: [ :create, :update ]
  after_commit :remove_cache, on: :destroy
  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: current_session).delete_all
  end

  # --- Business Logic Associations ---

  # --- Custom Methods ---
  # Alias for `parent_user` to provide a more descriptive name for the owner of a branch.
  def company_owner
    return self if parent_user.nil?
    parent_user
  end

  # Alias for `child_users` to represent users who are employees under this user.
  def employee_users
    child_users
  end

  def accessible_companies
    case system_role&.to_sym
    when :super_admin
      Company.all # Or [] if you want to keep them separated
    when :admin
      Company.all # Or [] if you want to keep them separated
    when :company_owner
      companies # Uses the association directly
    when :company_employee
      # Use &. to avoid errors if an employee record is missing
      [ employees&.map(&:company) ].flatten.compact
    when :company_customer
      # Customers might see companies they have orders with
      [ customers&.map(&:company) ].flatten.compact
    else
      []
    end
  end

  def permissions
    case system_role&.to_sym
    when :super_admin
      :all # Or [] if you want to keep them separated
    when :admin
      :all # Or [] if you want to keep them separated
    when :company_owner
      :all # Uses the association directly
    when :company_employee
      employee.permissions
    when :company_customer
      # Customers might see companies they have orders with
      {}
    else
      {}
    end
  end

  # New Company is a master-account (owner) flow: company owners can always
  # create more companies, and accounts that do not belong to any company yet
  # create their first one (fresh signups — including Google, which start as
  # :company_employee). Platform admins use the admin dashboard, and members of
  # existing companies (company_employee / company_customer) must not — company
  # creation promotes the creator to :company_owner (Company#initialize_company).
  def can_create_company?
    return false if system_role_admin? || system_role_super_admin?

    system_role_company_owner? || accessible_companies.empty?
  end
  # ----------------------------------------------------------------------------------------------------

  private

  def refresh_cache
    attrs = attributes
    self.class.defined_enums.each do |enum_name, mapping|
      value = attrs[enum_name]
      attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
    end
    Rails.sync_cache.write(
      "users_#{id}:v2",
      attrs,
      expires_in: USER_CACHE_EXPIRY
    )
  end

  def remove_cache
    Rails.sync_cache.delete("users_#{id}:v2")
  end
end

class User < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end


  has_many :sessions, dependent: :destroy
  has_many :sign_in_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: current_session).delete_all
  end

  # ----------------------------------------------------------------------------------------------------
  validates :name, uniqueness: true, allow_blank: true
  
  # --- Concerns ---
  # Includes functionality for handling user avatars, likely from `app/models/user/avatar_concern.rb`.
  include User::CacheConcern
  include User::AvatarConcern
  include User::ChatImagesConcern
  include AddressConcern

  # --- Business Logic Associations ---

  has_many :companies, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :customers, dependent: :destroy

  belongs_to :parent_user, class_name: "User", optional: true
  has_many :child_users, class_name: "User", foreign_key: "parent_user_id", dependent: :destroy

  enum :system_role, {
    super_admin: 0,
    admin: 1,
    company_owner: 2,
    company_employee: 3,
    company_customer: 4
  }, prefix: true

  enum :country_code, COUNTRIE_CODES, prefix: true

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

  include User::RetailConcern
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
  # ----------------------------------------------------------------------------------------------------
end

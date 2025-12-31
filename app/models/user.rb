class User < ApplicationRecord
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
    sessions.where.not(id: Current.session).delete_all
  end

  # ----------------------------------------------------------------------------------------------------
  # --- Concerns ---
  # Includes functionality for handling user avatars, likely from `app/models/user/avatar_concern.rb`.
  include User::AvatarConcern
  include User::ChatImagesConcern
  include Subscription::BuyerConcern
  include AddressConcern

  # --- Business Logic Associations ---

  has_many :company_groups, dependent: :destroy
  has_one :employee, dependent: :destroy
  has_one :customer, dependent: :destroy

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
  # Alias for `parent_user` to provide a more descriptive name for the owner of a company.
  def company_owner
    return self if parent_user.nil?
    parent_user
  end

  # Alias for `child_users` to represent users who are employees under this user.
  def employee_users
    child_users
  end

  include User::RetailConcern
  # ----------------------------------------------------------------------------------------------------
end

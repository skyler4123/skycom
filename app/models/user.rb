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

  # --- Concerns ---
  # Includes functionality for handling user avatars, likely from `app/models/user/avatar_concern.rb`.
  include User::AvatarConcern

  # --- Business Logic Associations ---
  # A user can own multiple companies. If the user is deleted, their companies are also destroyed.
  has_many :companies, dependent: :destroy
  has_one :employee, dependent: :destroy
  has_one :customer, dependent: :destroy
  
  belongs_to :parent_user, class_name: "User", optional: true
  has_many :child_users, class_name: "User", foreign_key: "parent_user_id", dependent: :destroy

  # Grouped business types with 1000-unit gaps for future expansion
  enum :company_business_type, { 
    # Group 1: General & Retail (0-999)
    retail: 0, 
    service: 1, 
    
    # Group 2: Food & Hospitality (1000-1999)
    food_service: 1000, 
    hospitality: 1001,
    
    # Group 3: Education (2000-2999)
    school: 2000,
    university: 2001,
    english_center: 2002,
    training_provider: 2003,
    
    # Group 4: Specialized & Knowledge Services (3000-3999)
    technology: 3000,
    finance: 3001,
    healthcare: 3002,
    media: 3003,
    real_estate: 3004,
    
    # Group 5: Professional Services (4000-4999)
    legal: 4000,
    consulting: 4001,
    accounting: 4002,
    marketing_agency: 4003,
    human_resources: 4004,

    # Group 6: Physical & Production (5000-5999)
    manufacturing: 5000,
    construction: 5001,
    transportation: 5002,
    agriculture: 5003,
    energy: 5004,
    utilities: 5005,

    # Group 7: Public Sector & Non-Profit (6000-6999)
    government_federal: 6000,
    government_state_local: 6001,
    military: 6002,
    non_profit: 6003,
    charity: 6004,
    
    # Group 8: Arts, Entertainment & Leisure (7000-7999)
    entertainment: 7000,
    arts_culture: 7001,
    sports_fitness: 7002
  }

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
end

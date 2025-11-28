class CompanyGroup < ApplicationRecord
  belongs_to :user
  has_many :companies, dependent: :destroy

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

  # --- Enums ---
  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }
  
  enum :ownership_type, { 
    publicly_traded: 0, 
    privately_held: 1 
  }
  
  enum :currency, { 
    usd: 840, 
    eur: 1,
    gbp: 826,
    vnd: 704,
    jpy: 392
  }
  
  # Grouped business types with 1000-unit gaps for future expansion
  enum :business_type, COMPANY_GROUP_BUSINESS_TYPES

  # Enum for the new fiscal_year_end_month column (1=January, 12=December)
  enum :fiscal_year_end_month, { 
    january: 1, february: 2, march: 3, april: 4, 
    may: 5, june: 6, july: 7, august: 8, 
    september: 9, october: 10, november: 11, december: 12
  }
  
  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
  validates :ownership_type, presence: true
  validates :status, presence: true
  
  # Validation for new administrative fields
  validates :registration_number, presence: true, uniqueness: true, if: :privately_held? # Typically required for private companies
  validates :vat_id, length: { maximum: 50 }, allow_blank: true
  validates :employee_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Validation for contact fields
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, length: { maximum: 20 }, allow_blank: true
  validates :website, format: URI::regexp(%w[http https]), allow_blank: true
  
  # Validation for address fields
  validates :country, presence: true
  validates :city, presence: true
  
  # Validation for operational fields
  # validates :fiscal_year_end_month, presence: true, numericality: { in: 1..12 }

end

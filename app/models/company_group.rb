class CompanyGroup < ApplicationRecord
  belongs_to :user
  belongs_to :timezone
  
  has_many :companies, dependent: :destroy

  has_many :tags, dependent: :destroy

  has_many :employee_groups, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :facility_groups, dependent: :destroy
  has_many :facilities, dependent: :destroy
  has_many :service_groups, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :product_groups, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :customer_groups, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :payment_method_appointments, dependent: :destroy
  has_many :task_groups, dependent: :destroy
  has_many :project_groups, dependent: :destroy
  has_many :cart_groups, dependent: :destroy
  has_many :notification_groups, dependent: :destroy
  has_many :payment_methods, through: :payment_method_appointments

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
  enum :business_type, { 
  # Group 1: General & Retail (0-999)
  retail: 0, 
  service: 1, 
  
  # Group 2: Food & Accommodation (1000-1999)
  restaurant: 1000,
  hotel: 1001,
  
  # Group 3: Medical (2000-2999)
  hospital: 2000,
  dental: 2001,
  optical: 2002,
  clinic: 2003,
  
  # Group 4: Education (3000-3999)
  education: 3000,
  university: 3001,
  english_center: 3002,
  
  # Group 5: Specialized & Knowledge Services (3000-3999)
  # technology: 3000,
  # finance: 3001,
  # healthcare: 3002,
  # media: 3003,
  # real_estate: 3004,
  
  # Group 6: Professional Services (4000-4999)
  # legal: 4000,
  # consulting: 4001,
  # accounting: 4002,
  # marketing_agency: 4003,
  # human_resources: 4004,

  # Group 7: Physical & Production (5000-5999)
  # manufacturing: 5000,
  # construction: 5001,
  # transportation: 5002,
  # agriculture: 5003,
  # energy: 5004,
  # utilities: 5005,

  # Group 8: Public Sector & Non-Profit (6000-6999)
  # government_federal: 6000,
  # government_state_local: 6001,
  # military: 6002,
  # non_profit: 6003,
  # charity: 6004,
  
  # Group 9: Arts, Entertainment & Leisure (7000-7999)
  # entertainment: 7000,
  # arts_culture: 7001,
  # sports_fitness: 7002
}

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

  include CompanyGroup::RetailConcern
  include CompanyGroup::EducationConcern
  include CompanyGroup::HospitalConcern
  include CompanyGroup::RestaurantConcern
end

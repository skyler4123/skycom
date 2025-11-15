class Company < ApplicationRecord
  belongs_to :user

  has_many :tags, dependent: :destroy
  has_many :employee_groups, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :policies, dependent: :destroy

  has_many :child_companies, class_name: "Company", foreign_key: "parent_company_id", dependent: :destroy
  belongs_to :parent_company, class_name: "Company", optional: true

  # --- Enums ---
  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }
  
  enum :kind, { 
    public: 0, 
    private: 1 
  }

  enum :business_type, { 
    # Group 1: General & Retail (0-999)
    retail: 0, 
    service: 1, 
    
    # Group 2: Food & Hospitality (1000-1999)
    food_service: 1000, 
    hospitality: 1001, # Hotels, resorts, tourism
    
    # Group 3: Education (2000-2999)
    school: 2000,
    university: 2001,
    english_center: 2002,
    training_provider: 2003, # Vocational, continuing education
    
    # Group 4: Specialized & Knowledge Services (3000-3999)
    technology: 3000, # Software, IT consulting, high-tech
    finance: 3001, # Banking, insurance, investment, etc.
    healthcare: 3002, # Hospitals, clinics, pharma, etc.
    media: 3003, # Publishing, broadcasting, entertainment
    real_estate: 3004, # Property management, development, sales
    
    # Group 5: Professional Services (4000-4999)
    legal: 4000, # Law firms, legal consulting
    consulting: 4001, # Management, strategy, general consulting
    accounting: 4002, # Accounting firms, tax services
    marketing_agency: 4003, # Advertising, PR, digital marketing
    human_resources: 4004, # Staffing, recruitment, HR consulting

    # Group 6: Physical & Production (5000-5999)
    manufacturing: 5000,
    construction: 5001, # Residential and commercial building
    transportation: 5002, # Logistics, shipping, airlines
    agriculture: 5003, # Farming, food production, fisheries
    energy: 5004, # Oil, gas, renewable power generation
    utilities: 5005, # Water, electric, waste management

    # Group 7: Public Sector & Non-Profit (6000-6999)
    government_federal: 6000,
    government_state_local: 6001,
    military: 6002,
    non_profit: 6003,
    charity: 6004,
    
    # Group 8: Arts, Entertainment & Leisure (7000-7999)
    entertainment: 7000, # Film, music, gaming
    arts_culture: 7001, # Museums, galleries, theaters
    sports_fitness: 7002 # Gyms, teams, sports leagues
  }
  
  # --- Validations ---
  validates :name, presence: true
  validates :business_type, presence: true
end

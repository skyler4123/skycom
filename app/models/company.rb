class Company < ApplicationRecord
  belongs_to :company_group

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


  # Self-referencing association for company hierarchy
  belongs_to :parent_company, class_name: "Company", optional: true
  has_many :child_companies, class_name: "Company", foreign_key: "parent_company_id", dependent: :destroy, inverse_of: :parent_company

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
  enum :business_type, COMPANY_BUSINESS_TYPES

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
  # Ensure the company's business_type matches the owning user's company_business_type (if set)
  validate :business_type_matches_user, if: -> { user.present? }
  # After creating a company, if the owning user's company_business_type is nil,
  # set it to this company's business_type (stored as integer on the user).
  after_create :set_user_company_business_type_if_nil
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

  private

  # Compares the company's enum-backed business_type to the integer stored on the user
  # - If the user has no `company_business_type` set, this validation is skipped.
  # - If the company's business_type is nil/blank, the presence validation will cover it.
  def business_type_matches_user
    return if user.company_business_type.nil?

    # company.business_type is the enum value as a string (eg. 'school').
    # Company.business_types maps string keys to integer values. Compare integers.
    company_business_type_value = Company.business_types[business_type] if business_type.present?

    if business_type.nil?
      errors.add(:business_type, "is not a valid business type")
      return
    end

    unless business_type == user.company_business_type
      expected_key = user.company_business_type
      errors.add(:business_type, "must match the owner's company_business_type (expected: #{expected_key})")
    end
  end

  # If the owning user's `company_business_type` is not set, persist this
  # company's business_type integer value to the user record.
  def set_user_company_business_type_if_nil
    return unless user.present?
    return unless user.company_business_type.nil?

    # Resolve integer value for this company's business_type enum
    business_type_value = Company.business_types[business_type] if business_type.present?
    return if business_type_value.nil?

    # Use update_column to avoid triggering user validations/callbacks in case
    # they would prevent the write. This is a small seed-like sync and is safe.
    begin
      user.update_column(:company_business_type, business_type_value)
    rescue => e
      Rails.logger.error("Failed to sync user.company_business_type for User##{user.id}: #{e.message}")
    end
  end

end

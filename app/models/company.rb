class Company < ApplicationRecord
  belongs_to :company_group

  has_many :tag_appointments, as: :appoint_to, dependent: :destroy
  has_many :tags, through: :tag_appointments

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
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :ownership_type, {
    publicly_traded: 0,
    privately_held: 1
  }

  # Grouped business types with 1000-unit gaps for future expansion
  enum :business_type, BUSINESS_TYPES, prefix: true

  enum :timezone, TIMEZONES, prefix: true
  enum :currency, CURRENCIES, prefix: true

  # Enum for the new fiscal_year_end_month column (1=January, 12=December)
  enum :fiscal_year_end_month, {
    january: 1, february: 2, march: 3, april: 4,
    may: 5, june: 6, july: 7, august: 8,
    september: 9, october: 10, november: 11, december: 12
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_group_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
  # validates :ownership_type, presence: true
  # validates :status, presence: true

  # Validation for new administrative fields
  validates :registration_number, presence: true, uniqueness: true, if: :privately_held? # Typically required for private companies
  validates :vat_id, length: { maximum: 50 }, allow_blank: true
  validates :employee_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Validation for contact fields
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, length: { maximum: 20 }, allow_blank: true
  validates :website, format: URI.regexp(%w[http https]), allow_blank: true

  # Validation for address fields
  validates :country, presence: true
  # validates :city, presence: true

  # Validation for operational fields
  # validates :fiscal_year_end_month, presence: true, numericality: { in: 1..12 }

  after_initialize :set_defaults_from_company_group, if: :new_record?

  private

  def set_defaults_from_company_group
    return unless company_group

    self.timezone ||= company_group.timezone
    self.currency ||= company_group.currency
  end
end

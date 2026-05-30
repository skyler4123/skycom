class Branch < ApplicationRecord
  include CategoryConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  include AddressConcern
  include TagConcern

  belongs_to :company
  belongs_to :category

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
  has_many :payment_method_appointments, dependent: :destroy
  has_many :task_groups, dependent: :destroy
  has_many :project_groups, dependent: :destroy
  has_many :cart_groups, dependent: :destroy
  has_many :notification_groups, dependent: :destroy
  has_many :payment_methods, through: :payment_method_appointments
  has_many :statistics, as: :owner
  has_many :warehouses, dependent: :destroy
  has_many :stocks, dependent: :destroy
  has_many :stock_exports, dependent: :destroy
  has_many :stock_imports, dependent: :destroy
  has_many :stock_transfers, dependent: :destroy

  # Self-referencing association for company hierarchy
  # belongs_to :parent_company, class_name: "Company", optional: true
  # has_many :child_branches, class_name: "Company", foreign_key: "parent_branch_id", dependent: :destroy, inverse_of: :parent_company

  # --- Enums ---
  enum :country_code, COUNTRIE_CODES, prefix: true
  enum :business_type, {
    # Physical Points of Sale
    storefront: 0,        # Main retail/customer-facing shop
    kiosk: 1,             # Small booth, pop-up, or sub-counter
    showroom: 2,          # Display only (common in high-end retail/fitness)

    # Fulfillment & Logistics
    warehouse: 10,        # Storage only, no walk-in customers
    distribution_center: 11, # Hub for moving goods to other branches
    dark_store: 12,       # Dedicated for online order picking

    # Service & Support
    service_point: 20,    # Repairs, customer support, or intake
    clinic_wing: 21,      # Specific to Hospital companies
    classroom_annex: 22,  # Specific to Education companies

    # Administrative
    headquarters: 90,     # Main office / Corporate
    administrative: 91,   # Back-office branch (Accounting, HR)

    virtual: 99           # Online-only branch
  }, prefix: true
  enum :timezone, TIMEZONES, prefix: true
  enum :currency_code, CURRENCIE_CODES, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # NOTE: ownership_type and fiscal_year_end_month columns were removed from schema
  # These enums are kept for future use when custom columns are re-added
  # enum :ownership_type, { publicly_traded: 0, privately_held: 1 }
  # enum :fiscal_year_end_month, {
  #   january: 1, february: 2, march: 3, april: 4,
  #   may: 5, june: 6, july: 7, august: 8,
  #   september: 9, october: 10, november: 11, december: 12
  # }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true

  # NOTE: registration_number, vat_id, employee_count columns were removed from schema
  # Validations kept for future reference:
  # validates :registration_number, presence: true, uniqueness: true, if: :privately_held?
  # validates :vat_id, length: { maximum: 50 }, allow_blank: true
  # validates :employee_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Validation for contact fields
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, length: { maximum: 20 }, allow_blank: true

  # NOTE: website column was removed from schema
  # validates :website, format: URI.regexp(%w[http https]), allow_blank: true

  after_initialize :set_defaults_from_company, if: :new_record?

  def subscription_buyer
    self.company.user
  end

  private

  def set_defaults_from_company
    return unless company

    self.timezone ||= company.timezone
    self.currency_code ||= company.currency_code
  end
end

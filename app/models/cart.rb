# frozen_string_literal: true

# Cart — Atomic purpose: company-scoped shopping/wishlist cart owned by a
# CartGroup.
#
# Why it exists: keeps a pre-order basket separate from the final Order, so a
# branch can hold shopping, wishlist, or saved-for-later items with its own
# category/property schema.
# How it works: belongs to company/branch/cart_group/category/property mapping;
# employees join through CartEmployeeAppointment. The checkout pipeline reads the
# cart and produces an Order.
# Main associations: belongs_to :company, :cart_group, :category,
# :property_mapping (required), :branch (optional); has_many :employees through
# :cart_employee_appointments (dependent: :destroy).
class Cart < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    shopping: 0,
    wishlist: 1,
    saved_for_later: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :cart_group
  belongs_to :category
  belongs_to :property_mapping

  has_many :cart_employee_appointments, dependent: :destroy
  has_many :employees, through: :cart_employee_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }

  validates :business_type, presence: true
end

# frozen_string_literal: true

# Event — Atomic purpose: one scheduled appointment/procedure/reservation/banquet
# that links customers, employees, services, facilities, stock, and orders.
#
# Why it exists: the event is the booking header; it holds the time window and
# business type while all participants and resources attach through atomic
# appointments (see docs/EVENTS.md).
# How it works: belongs to company, optional event_group/branch, category, and
# property mapping; validates end_at after start_at. EventConfig (per company +
# category) controls stock holds, order creation, and facility/host warnings.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :event_group and :branch (optional); has_many :employees, :branches,
# :customers, :services, :facilities, :stocks, :orders through their event
# appointments (all dependent: :destroy).
class Event < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    appointment: 0,
    procedure: 1,
    reservation: 2,
    banquet: 3
  }, prefix: true, default: :appointment

  # --- Associations ---
  belongs_to :event_group, optional: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :employee_event_appointments, dependent: :destroy
  has_many :employees, through: :employee_event_appointments
  has_many :branch_event_appointments, dependent: :destroy
  has_many :branches, through: :branch_event_appointments
  has_many :customer_event_appointments, dependent: :destroy
  has_many :customers, through: :customer_event_appointments
  has_many :event_service_appointments, dependent: :destroy
  has_many :services, through: :event_service_appointments
  has_many :event_facility_appointments, dependent: :destroy
  has_many :facilities, through: :event_facility_appointments
  has_many :event_stock_appointments, dependent: :destroy
  has_many :stocks, through: :event_stock_appointments
  has_many :event_order_appointments, dependent: :destroy
  has_many :orders, through: :event_order_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :business_type, presence: true
  validate :end_at_follows_start_at

  private

  def end_at_follows_start_at
    return if start_at.blank? || end_at.blank?
    return if end_at > start_at

    errors.add(:end_at, "must be after start time")
  end
end

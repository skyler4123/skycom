# app/models/concerns/address_concern.rb
module AddressConcern
  extend ActiveSupport::Concern

  ADDRESS_APPOINTMENT_CLASSES = {
    "Branch" => "AddressBranchAppointment",
    "Company" => "AddressCompanyAppointment",
    "Customer" => "AddressCustomerAppointment",
    "CustomerGroup" => "AddressCustomerGroupAppointment",
    "Department" => "AddressDepartmentAppointment",
    "Employee" => "AddressEmployeeAppointment",
    "EmployeeGroup" => "AddressEmployeeGroupAppointment",
    "User" => "AddressUserAppointment"
  }.freeze

  included do
    klass_name = ADDRESS_APPOINTMENT_CLASSES.fetch(name)
    owner_key = name.underscore.to_sym
    owner_fk = :"#{owner_key}_id"

    has_many :address_appointments,
             class_name: klass_name,
             foreign_key: owner_fk,
             dependent: :destroy

    # Direct access to all unique Address records assigned to this model
    has_many :addresses, through: :address_appointments, source: :address

    has_one :current_address_appointment, -> {
              where(lifecycle_status: :active).order(created_at: :desc)
            }, class_name: klass_name, foreign_key: owner_fk

    has_one :db_address, through: :current_address_appointment, source: :address
  end

  def address
    cache_key = "#{cache_key_with_version}/current_address"
    Rails.cache.fetch(cache_key) { db_address }
  end

  def address=(options)
    return if options.blank?
    # Convert string keys to symbols just in case
    opts = options.symbolize_keys
    attach_address(**opts)
  end

  def attach_address(**attributes)
    # 1. Ensure defaults for context
    b_type = attributes[:business_type] || :office
    w_status = attributes[:workflow_status] || :approved
    l_status = :active

    # 2. Find or create the address
    target_address = Address.find_or_create_by!(
      line_1: attributes[:line_1],
      line_2: attributes[:line_2],
      city: attributes[:city],
      state_or_province: attributes[:state_or_province],
      country: attributes[:country] || :vn,
      postal_code: attributes[:postal_code]
    )

    transaction do
      # 3. Archive old appointments of same type
      address_appointments.where(business_type: b_type)
                          .where(lifecycle_status: :active)
                          .update_all(lifecycle_status: address_appointments.klass.lifecycle_statuses[:archived])

      # 4. Create new appointment - Explicitly pass statuses
      attrs = {
        address: target_address,
        business_type: b_type,
        lifecycle_status: l_status,
        workflow_status: w_status
      }
      # Company tenant default derives via SetDefaultCompanyConcern from the
      # owner (which responds to company_id) or the address; no from/by.
      address_appointments.create!(attrs)

      touch if persisted?
    end
  end
end

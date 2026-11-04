# frozen_string_literal: true

# Maps an Operation type to its operation route and appends the appointment's
# location parameter. Adding an operation type means adding one route plus one entry
# here.
class OperationLaunchService
  ROUTES = {
    "pos" => :pos_company_operations_path,
    "booking" => :booking_company_operations_path,
    "inventory" => :inventory_company_operations_path,
    "reception" => :reception_company_operations_path,
    "kitchen" => :kitchen_company_operations_path,
    "housekeeping" => :housekeeping_company_operations_path,
    "store_manager" => :store_manager_company_operations_path
  }.freeze

  def self.call(company:, operation:, appointment:)
    helper = ROUTES.fetch(operation.operation_type)
    location = if appointment.is_a?(BranchOperationAppointment)
      { branch_id: appointment.branch_id }
    else
      { warehouse_id: appointment.warehouse_id }
    end

    Rails.application.routes.url_helpers.public_send(helper, company, operation, **location)
  end
end

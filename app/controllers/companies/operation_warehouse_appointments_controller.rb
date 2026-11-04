# frozen_string_literal: true

# Companies::OperationWarehouseAppointmentsController — warehouse-level operation toggles
# and metadata. Operation config overrides this row's metadata when effective config is
# built. Show/edit/update are shared via Companies::OperationAppointmentsController.
# Serves Stimulus: Companies_Operations_IndexController (index links),
#                  Companies_OperationWarehouseAppointments_ShowController (show),
#                  Companies_OperationWarehouseAppointments_EditController (edit, update)
# Endpoints: GET /companies/:company_id/operation_warehouse_appointments/:id(.json),
#            GET /companies/:company_id/operation_warehouse_appointments/:id/edit,
#            PATCH /companies/:company_id/operation_warehouse_appointments/:id
# Docs: docs/OPERATIONS.md
class Companies::OperationWarehouseAppointmentsController < Companies::OperationAppointmentsController
  private

  def appointment_scope
    current_company.operation_warehouse_appointments.includes(:operation, :warehouse)
  end

  def appointment_param_key
    :operation_warehouse_appointment
  end

  def appointment_path
    company_operation_warehouse_appointment_path(current_company, appointment)
  end

  def edit_appointment_path
    edit_company_operation_warehouse_appointment_path(current_company, appointment)
  end
end

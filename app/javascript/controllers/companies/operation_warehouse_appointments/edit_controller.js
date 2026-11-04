import EditController from "controllers/companies/operation_appointments/edit_controller"

// Warehouse operation appointment editor.
// Depends on BE: Companies::OperationWarehouseAppointmentsController#show + #update
export default class Companies_OperationWarehouseAppointments_EditController extends EditController {
  recordPath(companyId, appointmentId) {
    return Helpers.operation_warehouse_appointment_path(companyId, appointmentId)
  }

  payloadKey() {
    return "operation_warehouse_appointment"
  }
}

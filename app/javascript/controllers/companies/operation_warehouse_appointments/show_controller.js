import ShowController from "controllers/companies/operation_appointments/show_controller"

// Warehouse operation appointment details.
// Depends on BE: Companies::OperationWarehouseAppointmentsController#show
export default class Companies_OperationWarehouseAppointments_ShowController extends ShowController {
  get kind() {
    return "warehouse"
  }

  recordPath(companyId, appointmentId) {
    return Helpers.operation_warehouse_appointment_path(companyId, appointmentId)
  }

  editRecordPath(companyId, appointmentId) {
    return Helpers.edit_company_operation_warehouse_appointment_path(companyId, appointmentId)
  }
}

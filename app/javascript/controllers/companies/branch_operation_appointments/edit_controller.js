import EditController from "controllers/companies/operation_appointments/edit_controller"

// Branch operation appointment editor.
// Depends on BE: Companies::BranchOperationAppointmentsController#show + #update
export default class Companies_BranchOperationAppointments_EditController extends EditController {
  recordPath(companyId, appointmentId) {
    return Helpers.branch_operation_appointment_path(companyId, appointmentId)
  }

  payloadKey() {
    return "branch_operation_appointment"
  }
}

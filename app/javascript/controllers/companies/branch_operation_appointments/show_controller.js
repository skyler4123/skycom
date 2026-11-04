import ShowController from "controllers/companies/operation_appointments/show_controller"

// Branch operation appointment details.
// Depends on BE: Companies::BranchOperationAppointmentsController#show
export default class Companies_BranchOperationAppointments_ShowController extends ShowController {
  get kind() {
    return "branch"
  }

  recordPath(companyId, appointmentId) {
    return Helpers.branch_operation_appointment_path(companyId, appointmentId)
  }

  editRecordPath(companyId, appointmentId) {
    return Helpers.edit_company_branch_operation_appointment_path(companyId, appointmentId)
  }
}

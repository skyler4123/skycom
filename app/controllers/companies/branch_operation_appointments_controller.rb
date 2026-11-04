# frozen_string_literal: true

# Companies::BranchOperationAppointmentsController — branch-level operation toggles and
# metadata. This row's metadata overrides the Operation config when effective config
# is built. Show/edit/update are shared via Companies::OperationAppointmentsController.
# Serves Stimulus: Companies_Operations_IndexController (index links),
#                  Companies_BranchOperationAppointments_ShowController (show),
#                  Companies_BranchOperationAppointments_EditController (edit, update)
# Endpoints: GET /companies/:company_id/branch_operation_appointments/:id(.json),
#            GET /companies/:company_id/branch_operation_appointments/:id/edit,
#            PATCH /companies/:company_id/branch_operation_appointments/:id
# Docs: docs/OPERATIONS.md
class Companies::BranchOperationAppointmentsController < Companies::OperationAppointmentsController
  private

  def appointment_scope
    current_company.branch_operation_appointments.includes(:operation, :branch)
  end

  def appointment_param_key
    :branch_operation_appointment
  end

  def appointment_path
    company_branch_operation_appointment_path(current_company, appointment)
  end

  def edit_appointment_path
    edit_company_branch_operation_appointment_path(current_company, appointment)
  end
end

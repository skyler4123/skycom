# frozen_string_literal: true

# Mobile::Companies::Operations::PosController — Shell-First POS page for the
# mobile app. The response is only a mount point; Companies_Operations_Pos_ShowController
# hydrates the catalog, cart and payment UI from the web JSON endpoint.
# Serves Stimulus: Companies_Operations_Pos_ShowController (hydrate)
# Endpoints: GET /mobile/companies/:company_id/operations/pos/:operation_id
# Docs: docs/MOBILE.md, docs/ORDER_PROCESSING_V1.md
class Mobile::Companies::Operations::PosController < Mobile::Companies::BaseController
  before_action :set_operation
  before_action :set_appointment
  before_action :authorize_operation!

  def show
    render html: shell_html.html_safe, layout: true
  end

  private

  def set_operation
    @operation = current_company.operations.find_by!(id: params[:operation_id], operation_type: :pos)
  end

  def set_appointment
    @appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: @operation,
      employee: current_employee,
      branch_id: params[:branch_id]
    )

    return if @appointment&.workflow_status_active?

    redirect_to mobile_company_operations_path(current_company),
      alert: "No active operation found for this location."
  end

  def authorize_operation!
    return if @operation.accessible_by?(current_employee, appointment: @appointment)

    redirect_to mobile_company_operations_path(current_company),
      alert: "You do not have access to this operation."
  end

  # The mobile layout has no shared Stimulus wrapper, so the shell carries the
  # controller and the identifiers the POS controller needs to hydrate.
  def shell_html
    <<~HTML
      <div class="min-h-dvh bg-background"
        data-controller="companies--operations--pos--show darkmode"
        data-company-id="#{@company.id}"
        data-operation-id="#{@operation.id}"
        data-user-name="#{ERB::Util.html_escape(@employee.name)}"
        data-user-role="#{ERB::Util.html_escape(@employee.roles.first&.name || "Employee")}"></div>
    HTML
  end
end

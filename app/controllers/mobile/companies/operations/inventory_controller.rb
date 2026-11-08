# frozen_string_literal: true

# Mobile::Companies::Operations::InventoryController — Shell-First inventory
# console for the mobile/tablet app. The response is only a mount point;
# Companies_Operations_Inventory_ShowController hydrates the stock ledger,
# metrics, docks, zone capacity and audit state from the web JSON endpoint.
# Inventory is warehouse-scoped, so the shell resolves an
# OperationWarehouseAppointment via warehouse_id (or the employee's branch).
# Serves Stimulus: Companies_Operations_Inventory_ShowController (hydrate)
# Endpoints: GET /mobile/companies/:company_id/operations/inventory/:operation_id
# Docs: docs/MOBILE.md, docs/OPERATIONS.md, docs/STOCK.md
class Mobile::Companies::Operations::InventoryController < Mobile::Companies::BaseController
  before_action :set_operation
  before_action :set_appointment
  before_action :authorize_operation!

  def show
    render html: shell_html.html_safe, layout: true
  end

  private

  def set_operation
    @operation = current_company.operations.find_by!(id: params[:operation_id], operation_type: :inventory)
  end

  def set_appointment
    @appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: @operation,
      employee: @employee,
      warehouse_id: params[:warehouse_id]
    )

    return if @appointment&.workflow_status_active?

    redirect_to mobile_company_operations_path(current_company),
      alert: "No active operation found for this location."
  end

  def authorize_operation!
    return if @operation.accessible_by?(@employee, appointment: @appointment)

    redirect_to mobile_company_operations_path(current_company),
      alert: "You do not have access to this operation."
  end

  # The mobile layout has no shared Stimulus wrapper, so the shell carries the
  # controller and the identifiers the inventory controller needs to hydrate.
  def shell_html
    <<~HTML
      <div class="min-h-dvh bg-background"
        data-controller="companies--operations--inventory--show darkmode"
        data-company-id="#{@company.id}"
        data-operation-id="#{@operation.id}"
        data-user-name="#{ERB::Util.html_escape(@employee.name)}"
        data-user-role="#{ERB::Util.html_escape(@employee.category&.name.presence || @employee.roles.first&.name || "Employee")}"></div>
    HTML
  end
end

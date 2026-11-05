# frozen_string_literal: true

# Companies::OperationsController — operation appointments (Shell-First).
# Index caches the company-level appointment payload for OPERATIONS_CACHE_EXPIRY,
# applies q/operation_type/workflow_status/location filters, and computes the
# per-employee accessible flag after the cache read. Launch resolves the
# appointment and redirects to the purpose-specific operation.
# Serves Stimulus: Companies_Operations_IndexController (index, launch)
# Endpoints: GET /companies/:company_id/operations(.json?q=&operation_type=&workflow_status=&location=),
#            GET /companies/:company_id/operations/:id/launch
# Docs: docs/OPERATIONS.md
class Companies::OperationsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        rows = cached_appointment_rows
        filtered = filter_appointment_rows(rows)

        render json: {
          operation_appointments: filtered.map { |row| row.merge("accessible" => accessible?(row)) },
          filters: appointment_filter_options(rows)
        }
      end
    end
  end

  def launch
    operation = current_company.operations.find(params[:id])
    appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: operation,
      employee: current_employee,
      branch_id: params[:branch_id],
      warehouse_id: params[:warehouse_id]
    )

    return render_launch_error("No active operation found for this location.") unless appointment
    return render_launch_error("This operation is inactive.") unless appointment.workflow_status_active?
    return render_launch_error("You do not have access to this operation.", status: :forbidden) unless operation.accessible_by?(current_employee, appointment: appointment)

    launch_path = OperationLaunchService.call(
      company: current_company,
      operation: operation,
      appointment: appointment
    )

    respond_to do |format|
      format.html { redirect_to launch_path }
      format.json { render json: { launch_path: launch_path } }
    end
  end

  private

  def operation_appointments
    branch_appointments = current_company.branch_operation_appointments.includes(:operation, :branch).to_a
    warehouse_appointments = current_company.operation_warehouse_appointments.includes(:operation, :warehouse).to_a

    (branch_appointments + warehouse_appointments).sort_by do |appointment|
      [
        appointment.operation.name.to_s.downcase,
        appointment.is_a?(BranchOperationAppointment) ? 0 : 1,
        OperationSerializer.location(appointment)["name"].to_s.downcase
      ]
    end
  end

  def cached_appointment_rows
    Rails.sync_cache.fetch(
      CacheKeyService.company_operation_appointments(current_company.id),
      expires_in: OPERATIONS_CACHE_EXPIRY
    ) do
      operation_appointments.map do |appointment|
        OperationSerializer.appointment(appointment, launch_path: launch_path_for(appointment))
      end
    end
  end

  def filter_appointment_rows(rows)
    filtered = rows

    if params[:q].present?
      query = params[:q].to_s.downcase
      filtered = filtered.select do |row|
        [
          row.dig("operation", "name"),
          row.dig("operation", "code"),
          row.dig("location", "name")
        ].compact.any? { |value| value.to_s.downcase.include?(query) }
      end
    end

    filtered = filtered.select { |row| row.dig("operation", "operation_type") == params[:operation_type] } if params[:operation_type].present?
    filtered = filtered.select { |row| row["workflow_status"] == params[:workflow_status] } if params[:workflow_status].present?
    filtered = filtered.select { |row| "#{row["kind"]}:#{row.dig("location", "id")}" == params[:location] } if params[:location].present?

    filtered
  end

  def appointment_filter_options(rows)
    operation_types = rows.map { |row| row.dig("operation", "operation_type") }.compact.uniq

    {
      operation_types: operation_types.map do |operation_type|
        {
          value: operation_type,
          name: OPERATION_TYPES.dig(operation_type.to_sym, :label) || operation_type.humanize
        }
      end,
      statuses: BranchOperationAppointment.workflow_statuses.keys.map do |status|
        { value: status, name: status.split("_").map(&:capitalize).join(" ") }
      end,
      locations: rows.map do |row|
        {
          value: "#{row["kind"]}:#{row.dig("location", "id")}",
          name: row.dig("location", "name"),
          kind: row["kind"]
        }
      end.uniq { |location| location[:value] }.sort_by { |location| location[:name].to_s.downcase }
    }
  end

  def accessible?(row)
    return true if current_employee.owner_role?

    local_roles = row.dig("metadata", "roles")
    local_roles = local_roles.is_a?(Array) ? local_roles.map(&:to_s) : []
    allowed = Array(row["access_roles"]).map(&:to_s)
    return false if allowed.empty? && local_roles.any?
    return true if allowed.empty?

    Operation.roles_allow_access?(
      roles: allowed,
      employee: current_employee,
      role_names: employee_role_names
    )
  end

  def employee_role_names
    @employee_role_names ||= current_employee.roles.pluck(:name)
  end

  def launch_path_for(appointment)
    if appointment.is_a?(BranchOperationAppointment)
      launch_company_operation_path(current_company, appointment.operation, branch_id: appointment.branch_id)
    else
      launch_company_operation_path(current_company, appointment.operation, warehouse_id: appointment.warehouse_id)
    end
  end

  def render_launch_error(message, status: :unprocessable_content)
    respond_to do |format|
      format.html do
        redirect_to company_operations_path(current_company), alert: message
      end
      format.json { render json: { errors: [ message ] }, status: status }
    end
  end
end

# app/controllers/companies/permissions_controller.rb
#
# Permissions dashboard (role-grouped policy toggles + resource setup).
# Writes audit: Companies::PermissionLogsController via PermissionLogs::WriteService
# (explicit log on update/create — never blocks the mutation).
class Companies::PermissionsController < Companies::ApplicationController
  before_action :authorize_permission_management, only: [ :update, :create ]

  # Shell First pattern - index action returns empty HTML, Stimulus renders content
  def index
    authorize current_employee, :index?, policy_class: Companies::PermissionsPolicy

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { roles: current_company.permissions, authorized: can_manage_permissions? } }
    end
  end

  def update
    return render json: { errors: [ "Unauthorized" ] }, status: :forbidden unless can_manage_permissions?
    appointment = current_company.policy_role_appointments.includes(:role, :policy).find(params[:id])
    policy = appointment.policy
    role = appointment.role
    from_status = appointment.workflow_status
    tag_conditions_before = policy.tag_conditions

    if params.dig(:policy_appointment, :workflow_status).in?([ true, false ])
      ws = params[:policy_appointment][:workflow_status] ? :active : :inactive
      appointment.update!(workflow_status: ws)
      log_permission_change(
        action: ws == :active ? :granted : :revoked,
        role: role, policy: policy, appointment: appointment,
        from_workflow_status: from_status, to_workflow_status: ws.to_s
      )
    end

    if params.dig(:policy, :metadata, :tag_conditions).is_a?(ActionController::Parameters)
      policy.update!(tag_conditions: params[:policy][:metadata][:tag_conditions].to_unsafe_h)
      log_permission_change(
        action: :conditions_changed,
        role: role, policy: policy.reload, appointment: appointment,
        tag_conditions_before: tag_conditions_before,
        tag_conditions_after: policy.tag_conditions
      )
    end

    current_company.clear_permissions_cache
    render json: {
      message: "Permission updated successfully",
      policy_appointment: { id: appointment.id, workflow_status: appointment.workflow_status },
      policy: { id: policy.id, tag_conditions: policy.reload.tag_conditions || {} }
    }
  end

  def create
    role_id = params.dig(:permission, :role_id)
    resource_name = params.dig(:permission, :resource_name)

    # Validate role exists and belongs to company
    role = current_company.roles.find_by(id: role_id)
    return render json: { errors: [ "Role not found" ] }, status: :not_found unless role

    # Validate resource_name is in company's resource_names
    unless current_company.resource_names.include?(resource_name)
      return render json: { errors: [ "Invalid resource name" ] }, status: :unprocessable_content
    end

    # Check if resource already has policies for this role
    existing_policies = Policy.where(company: current_company, resource: resource_name)
                             .joins(:policy_role_appointments)
                             .where(policy_role_appointments: { role_id: role.id })
                             .exists?

    if existing_policies
      return render json: { errors: [ "Resource already assigned to this role" ] }, status: :unprocessable_content
    end

    # Create policies for the role
    role.setup_policies_for!(resource_name)
    current_company.clear_permissions_cache

    log_resource_added(role: role, resource_name: resource_name)

    render json: { message: "Resource added successfully" }
  end

  private

  # Immutable audit row — plain snapshot, never blocks the permission save.
  def log_permission_change(action:, role: nil, policy: nil, appointment: nil,
    from_workflow_status: nil, to_workflow_status: nil,
    tag_conditions_before: nil, tag_conditions_after: nil)
    PermissionLogs::WriteService.call(
      company: current_company,
      action: action,
      actor: current_employee,
      role: role,
      policy: policy,
      appointment: appointment,
      from_workflow_status: from_workflow_status,
      to_workflow_status: to_workflow_status,
      tag_conditions_before: tag_conditions_before,
      tag_conditions_after: tag_conditions_after
    )
  rescue => e
    Rails.logger.error("[PermissionLog] #{e.message}")
  end

  def log_resource_added(role:, resource_name:)
    current_company.policies
      .where(resource: resource_name)
      .joins(:policy_role_appointments)
      .where(policy_role_appointments: { role_id: role.id })
      .includes(:policy_role_appointments).find_each do |policy|
      appointment = policy.policy_role_appointments.find { |a| a.role_id == role.id }
      log_permission_change(action: :resource_added, role: role, policy: policy, appointment: appointment)
    end
  rescue => e
    Rails.logger.error("[PermissionLog] #{e.message}")
  end

  def can_manage_permissions?
    # 1. Company owner can always manage
    return true if current_user == current_company.user

    # 2. Employee with PolicyRoleAppointment CRUD permission
    employee = current_user.employees.find_by(company: current_company)
    return false unless employee

    employee.can?(:create, PolicyRoleAppointment) ||
    employee.can?(:update, PolicyRoleAppointment) ||
    employee.can?(:destroy, PolicyRoleAppointment)
  end

  def authorize_permission_management
    render json: { errors: [ "Unauthorized" ] }, status: :forbidden unless can_manage_permissions?
  end
end

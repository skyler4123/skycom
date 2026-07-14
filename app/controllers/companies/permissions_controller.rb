class Companies::PermissionsController < Companies::ApplicationController
  feature_key :custom_roles

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
    appointment = current_company.policy_appointments.find(params[:id])
    policy = appointment.policy

    if params.dig(:policy_appointment, :workflow_status).in?([ true, false ])
      ws = params[:policy_appointment][:workflow_status] ? :active : :inactive
      appointment.update!(workflow_status: ws)
    end

    if params.dig(:policy, :tag_conditions).is_a?(ActionController::Parameters)
      policy.update!(tag_conditions: params[:policy][:tag_conditions].to_unsafe_h)
    end

    current_company.clear_permissions_cache
    render json: {
      message: "Permission updated successfully",
      policy_appointment: { id: appointment.id, workflow_status: appointment.workflow_status },
      policy: { id: policy.id, tag_conditions: policy.reload.tag_conditions }
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
      return render json: { errors: [ "Invalid resource name" ] }, status: :unprocessable_entity
    end

    # Check if resource already has policies for this role
    existing_policies = Policy.where(company: current_company, resource: resource_name)
                             .joins(:policy_appointments)
                             .where(policy_appointments: { appoint_to: role })
                             .exists?

    if existing_policies
      return render json: { errors: [ "Resource already assigned to this role" ] }, status: :unprocessable_entity
    end

    # Create policies for the role
    role.setup_policies_for!(resource_name)
    current_company.clear_permissions_cache

    render json: { message: "Resource added successfully" }
  end

  private

  def can_manage_permissions?
    # 1. Company owner can always manage
    return true if current_user == current_company.user

    # 2. Employee with PolicyAppointment CRUD permission
    employee = current_user.employees.find_by(company: current_company)
    return false unless employee

    employee.can?(:create, PolicyAppointment) ||
    employee.can?(:update, PolicyAppointment) ||
    employee.can?(:destroy, PolicyAppointment)
  end

  def authorize_permission_management
    render json: { errors: [ "Unauthorized" ] }, status: :forbidden unless can_manage_permissions?
  end
end

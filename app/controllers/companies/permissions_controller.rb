class Companies::PermissionsController < Companies::ApplicationController
  before_action :authorize_permission_management, only: [:update]

  # Shell First pattern - index action returns empty HTML, Stimulus renders content
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { roles: current_company.permissions, authorized: can_manage_permissions? } }
    end
  end

  def update
    # This endpoint belongs to Permission but we dont create this model, in this endpoint, id is id of PolicyAppointment
    return render json: { error: "Unauthorized" }, status: :forbidden unless can_manage_permissions?
    appointment = current_company.policy_appointments.find(params[:id])

    if appointment.update(workflow_status: params[:policy_appointment][:workflow_status])
      current_company.clear_permissions_cache
      render json: { policy_appointment: appointment }
    else
      render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
    end
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
    render json: { error: "Unauthorized" }, status: :forbidden unless can_manage_permissions?
  end
end
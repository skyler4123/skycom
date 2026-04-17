class Companies::PermissionsController < Companies::ApplicationController
  # Shell First pattern - index action returns empty HTML, Stimulus renders content
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { roles: current_company.permissions } }
    end
  end

  def create
    policy = current_company.policies.find(params[:policy_appointment][:policy_id])
    role = current_company.roles.find(params[:policy_appointment][:role_id])

    appointment = PolicyAppointment.find_or_initialize_by(
      policy: policy,
      appoint_to: role
    )

    appointment.workflow_status = :active

    if appointment.save
      current_company.clear_permissions_cache
      render json: { policy_appointment: appointment }
    else
      render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    appointment = current_company.policy_appointments.find(params[:id])

    if appointment.update(workflow_status: params[:policy_appointment][:workflow_status])
      current_company.clear_permissions_cache
      render json: { policy_appointment: appointment }
    else
      render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end
end

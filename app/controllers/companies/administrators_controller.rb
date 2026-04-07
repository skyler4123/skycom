# app/controllers/companies/administrators_controller.rb
class Companies::AdministratorsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # Assuming current_company.permissions returns a Hash like: { "Admin" => { policies: [...] } }
        @administrators = current_company.permissions
        render json: { administrators: @administrators }
      end
    end
  end

  def update_permission
    role = current_company.roles.find(params[:role_id])

    policy = current_company.policies.find_or_create_by!(
      resource: params[:resource],
      action: params[:permission_action]
    ) do |p|
      p.name = "Can #{params[:permission_action]} #{params[:resource]}"
      p.business_type = :operational
    end

    # 3. Toggle with "Minimum 1" Safety Check
    if params[:status] == true
      role.policy_appointments.find_or_create_by!(policy: policy)
    else
      # Check how many policies this role has for THIS specific resource
      resource_policy_count = role.policies.where(resource: params[:resource]).count

      if resource_policy_count > 1
        role.policy_appointments.where(policy: policy).destroy_all
      else
        # Return a 422 Unprocessable Entity if it's the last one
        return render json: {
          error: "Cannot remove the last permission for '#{params[:resource]}'. At least one action must remain to keep the resource visible."
        }, status: :unprocessable_entity
      end
    end

    render json: { status: :ok }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Role not found" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

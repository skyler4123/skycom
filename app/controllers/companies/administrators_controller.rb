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
    # 1. Find the role strictly within this company
    role = current_company.roles.find(params[:role_id])
    
    # 2. Find or create the Policy template
    # We use 'action' and 'resource' to uniquely identify what the policy does
    policy = current_company.policies.find_or_create_by!(
      resource: params[:resource],
      action: params[:permission_action]
    ) do |p|
      p.name = "Can #{params[:permission_action]} #{params[:resource]}"
      p.business_type = :operational
    end

    # 3. Toggle the relationship
    if params[:status] == true
      role.policy_appointments.find_or_create_by!(policy: policy)
    else
      role.policy_appointments.where(policy: policy).destroy_all
    end

    # 4. Success response
    render json: { status: :ok }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Role not found" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

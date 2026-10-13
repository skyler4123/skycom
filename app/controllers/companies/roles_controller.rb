# app/controllers/companies/roles_controller.rb
#
# Roles dashboard API (Shell-First). OWNER-ONLY: Companies::RolesPolicy allows
# solely the company owner — Role grants (if present on older companies) are
# ignored. Roles own their "All <Role>" system NotificationTag for life
# (see Role callbacks): create ensures it, rename follows it, destroy removes
# it — the destroy flash below warns about that.
# Serves Stimulus: Companies_Roles_IndexController (index JSON),
#                  Companies_Roles_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/roles(.json) + nested CRUD — see config/routes.rb
# Docs: docs/MODEL_CALLBACKS.md (Role rows)
class Companies::RolesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.roles.order(:name)
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { roles: format_roles(@results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    role = current_company.roles.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { role: format_role(role) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    role = current_company.roles.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { role: format_role(role) } }
    end
  end

  def create
    if owner_params?(role_params)
      redirect_to new_company_role_path(current_company),
        alert: "The owner role is managed by the system and cannot be created here."
      return
    end

    role = current_company.roles.new(role_params)
    if role.save
      redirect_to company_role_path(current_company, role), notice: "Role created successfully"
    else
      redirect_to new_company_role_path(current_company),
        alert: role.errors.full_messages.to_sentence
    end
  end

  def update
    role = current_company.roles.find(params[:id])

    if owner_params?(role_params) || role.name == OWNER_BUSINESS_TYPE
      redirect_to company_role_path(current_company, role),
        alert: "The owner role is managed by the system and cannot be changed here."
      return
    end

    renamed = role_params[:name].present? && role_params[:name] != role.name
    if role.update(role_params)
      message = "Role updated successfully."
      message += " Its notification tag was renamed to '#{role.paired_tag_name}'." if renamed
      redirect_to company_role_path(current_company, role), notice: message
    else
      redirect_to edit_company_role_path(current_company, role),
        alert: role.errors.full_messages.to_sentence
    end
  end

  def destroy
    role = current_company.roles.find(params[:id])

    if role.name == OWNER_BUSINESS_TYPE
      redirect_to company_role_path(current_company, role),
        alert: "The owner role cannot be deleted."
      return
    end

    tag_name = role.paired_tag_name
    subscriptions = EmployeeNotificationTagAppointment
      .where(company: current_company)
      .where(notification_tag: NotificationTag.where(company: current_company, name: tag_name))
      .count
    role.destroy!
    redirect_to company_roles_path(current_company),
      notice: "Role '#{role.name}' deleted. Its notification tag '#{tag_name}' was removed also (#{subscriptions} subscriptions removed) — please be aware that members will no longer receive role broadcasts!"
  end

  private

  def owner_params?(permitted)
    permitted[:name] == OWNER_BUSINESS_TYPE || permitted[:business_type] == OWNER_BUSINESS_TYPE
  end

  def role_params
    params.require(:role).permit(:name, :description, :business_type, :workflow_status)
  end

  def format_role(role)
    role.as_json(only: [
      :id, :name, :description,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      "paired_tag_name" => role.paired_tag_name
    )
  end

  def format_roles(roles)
    roles.map { |role| format_role(role) }
  end
end

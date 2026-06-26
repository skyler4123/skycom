# app/controllers/concerns/companies/authorizable.rb
module Companies::Authorizable
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    before_action :authorize_current_employee!
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def authorize_current_employee!
    raise Pundit::NotAuthorizedError unless current_employee

    # 1. Derive Policy Class (e.g., Companies::EmployeesController -> Companies::EmployeesPolicy)
    # We remove "Controller" but keep the plural "Employees"
    policy_class_name = self.class.name.sub("Controller", "Policy")

    # 2. Derive Action (e.g., 'index' -> 'index?')
    query_method = "#{action_name}?"

    begin
      policy_class = policy_class_name.constantize
      # We pass current_employee as the 'record' to the policy
      authorize current_employee, query_method, policy_class: policy_class
    rescue NameError
      # If the policy doesn't exist, we can choose to deny access or allow it.
      # For an ERP, denying by default is safer.
      message = "Security Policy for #{policy_class_name} not found."

      respond_to do |format|
        format.html do
          flash[:alert] = message
          redirect_to(request.referrer || root_path)
        end
        format.json do
          render json: { errors: [ message ] }, status: :internal_server_error
        end
      end
    end
  end

  def block_access!
    return if current_company&.is_accessible?

    respond_to do |format|
      format.html do
        redirect_to company_billing_path(current_company), alert: "Your account is suspended. Please resolve outstanding invoices."
      end
      format.json do
        render json: { errors: [ "Account is suspended" ] }, status: :forbidden
      end
    end
  end

  def user_not_authorized(exception)
    message = "You are not authorized to perform this action."

    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_to(request.referrer || root_path)
      end
      format.json do
        render json: {
          errors: [ message ],
          policy: exception.policy.class.to_s,
          action: exception.query
        }, status: :forbidden
      end
    end
  end
end

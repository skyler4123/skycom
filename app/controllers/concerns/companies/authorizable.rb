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
    return unless current_employee

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
      render json: { errors: [ "Security Policy for #{policy_class_name} not found." ] }, status: :internal_server_error
    end
  end

  def user_not_authorized(exception)
    # Your existing logic to return the 'errors' array to Stimulus
    render json: {
      errors: [ "You are not authorized to perform this action." ]
    }, status: :forbidden
  end
end

# app/controllers/concerns/mobile/companies/authorizable.rb
module Mobile::Companies::Authorizable
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    before_action :authorize_current_employee!
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def current_employee
    @employee
  end

  def authorize_current_employee!
    raise Pundit::NotAuthorizedError unless current_employee

    policy_class_name = self.class.name.sub("Controller", "Policy")
    query_method = "#{action_name}?"

    begin
      policy_class = policy_class_name.constantize
      authorize current_employee, query_method, policy_class: policy_class
    rescue NameError
      message = "Security Policy for #{policy_class_name} not found."

      respond_to do |format|
        format.html do
          flash[:alert] = message
          redirect_to (@company.present? ? mobile_company_home_path(@company) : (request.referrer || root_path))
        end
        format.json do
          render json: { errors: [ message ] }, status: :internal_server_error
        end
      end
    end
  end

  def user_not_authorized(exception)
    message = "You are not authorized to perform this action."

    respond_to do |format|
      format.html do
        redirect_to (@company.present? ? mobile_company_home_path(@company) : (request.referrer || root_path)), alert: message
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

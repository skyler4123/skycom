# app/controllers/concerns/companies/authorizable.rb
module Companies::Authorizable
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization

    # Catch Pundit errors and route them to our custom handler
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  # A helper to authorize the employee for a specific action/resource
  # Usage: authorize_employee!(:read, PolicyAppointment, policy_class: Companies::PermissionPolicy)
  def authorize_employee!(action, record, policy_class:)
    authorize current_employee, "#{action}?", policy_class: policy_class
  end

  def user_not_authorized(exception)
    # Wrap the single message in an array to match Rails validation style
    error_messages = [ "You are not authorized to perform this action." ]

    respond_to do |format|
      format.html do
        flash[:alert] = error_messages.first
        redirect_to(request.referrer || root_path)
      end
      format.json do
        render json: {
          errors: error_messages, # Consistency: always an array
          policy: exception.policy.class.to_s,
          action: exception.query
        }, status: :forbidden
      end
    end
  end
end

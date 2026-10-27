class Mobile::Companies::BaseController < Mobile::BaseController
  before_action :set_employee_and_company
  include Mobile::Companies::Authorizable

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def set_employee_and_company
    raise ActiveRecord::RecordNotFound unless current_user

    @employee = current_user.employees.includes(*employee_includes).find_by!(company_id: params[:company_id])
    @company = @employee.company
  end

  def employee_includes
    %i[company branch]
  end

  def not_found
    head :not_found
  end
end

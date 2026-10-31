class Mobile::Companies::BaseController < Mobile::BaseController
  before_action :set_employee_and_company
  include Mobile::Companies::Authorizable
  include Mobile::Companies::SuspendedCompanyConcern
  include ApplicationController::WebsocketConcern

  before_action :set_websocket_channels

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def set_employee_and_company
    raise ActiveRecord::RecordNotFound unless current_user

    @employee = current_user.employees.includes(*employee_includes).find_by!(company_id: params[:company_id])
    @company = @employee.company
    @current_company = @company
  end

  def current_company
    @company
  end

  def company_utc_offset
    @company_utc_offset ||= Company.timezones.fetch(@company.timezone.to_s, 0) * 3600
  end

  def employee_includes
    %i[company branch]
  end

  def not_found
    head :not_found
  end
end

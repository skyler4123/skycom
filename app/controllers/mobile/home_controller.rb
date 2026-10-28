class Mobile::HomeController < Mobile::BaseController
  # Signed-in users without an employee record land here. Users with an
  # employee record are redirected to their company-scoped home.
  def index
    @employee = current_user.employees.includes(:company, :branch).first
    if @employee
      redirect_to mobile_company_home_path(@employee.company)
      return
    end

    render "mobile/companies/home/index"
  end
end

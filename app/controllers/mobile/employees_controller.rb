class Mobile::EmployeesController < Mobile::BaseController
  def show
    @employee = current_user.employees.first

    unless @employee
      redirect_to mobile_home_path, alert: "No employee record found" and return
    end
  end
end

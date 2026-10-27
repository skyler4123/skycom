class Mobile::SessionsController < Mobile::BaseController
  skip_before_action :authenticate, only: [ :new, :create ]

  def new
    redirect_to_mobile_home_for(current_user) if is_signed_in? && current_user
  end

  def create
    @email = params[:email]

    if user = User.authenticate_by(email: params[:email], password: params[:password])
      session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: session.single_access_token)
      update_cookie(session: session, user: user)
      redirect_to_mobile_home_for(user, notice: "Signed in")
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    current_session&.destroy
    session.delete(:mobile_company_id)
    cookies.clear
    redirect_to mobile_sign_in_path, notice: "Signed out"
  end

  private

  def redirect_to_mobile_home_for(user, **options)
    employee = mobile_employee_for(user)

    if employee
      session[:mobile_company_id] = employee.company_id
      redirect_to mobile_company_home_path(employee.company), **options
    else
      redirect_to mobile_home_path, **options
    end
  end

  def mobile_employee_for(user)
    employees = user.employees.includes(:company)
    employees.find_by(company_id: session[:mobile_company_id]) || employees.first
  end
end

class Mobile::Companies::PayrollUnlocksController < Mobile::Companies::BaseController
  # How long one password confirmation keeps the payroll screen accessible.
  MOBILE_PAYROLL_UNLOCK_WINDOW = 5.minutes

  def new
  end

  def create
    session.delete(:mobile_payroll_unlock_company_id)
    session.delete(:mobile_payroll_unlock_expires_at)

    unless current_user.authenticate(params[:password].to_s)
      flash.now[:alert] = "Incorrect password"
      render :new, status: :unprocessable_content
      return
    end

    session[:mobile_payroll_unlock_company_id] = @company.id
    session[:mobile_payroll_unlock_expires_at] = MOBILE_PAYROLL_UNLOCK_WINDOW.from_now.to_i

    redirect_to mobile_company_payroll_path(@company, month: params[:month].presence)
  end
end

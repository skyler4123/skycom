# frozen_string_literal: true

# Mobile::SessionsController — Shell-First sign-in page. The form submits
# natively (data-turbo="false") so the post-login redirect URL stays visible to
# the Hotwire Native shell, which reads the company id from it. Invalid
# credentials re-render the same shell with data-errors/data-values.
# Serves Stimulus: Mobile_Sessions_NewController
# Endpoints: GET /mobile/sign_in(.json), POST /mobile/sign_in, DELETE /mobile/sign_out
# Docs: docs/MOBILE.md §2-§4
class Mobile::SessionsController < Mobile::BaseController
  skip_before_action :authenticate, only: [ :new, :create ]

  def new
    return redirect_to_mobile_home_for(current_user) if is_signed_in? && current_user

    respond_to do |format|
      format.html do
        @page_title = "Sign in · Skycom"
        render_mobile_shell(json_url: mobile_sign_in_path(format: :json))
      end
      format.json { render json: { email: nil } }
    end
  end

  def create
    @email = params[:email]

    if user = User.authenticate_by(email: params[:email], password: params[:password])
      session = user.sessions.create!(single_access_token: SecureRandom.hex(20))
      user.update!(single_access_token: session.single_access_token)
      update_cookie(session: session, user: user)
      redirect_to_mobile_home_for(user, notice: "Signed in")
    else
      render_invalid_credentials
    end
  end

  def destroy
    current_session&.destroy
    session.delete(:mobile_company_id)
    session.delete(:mobile_payroll_unlock_company_id)
    session.delete(:mobile_payroll_unlock_expires_at)
    cookies.clear
    redirect_to mobile_sign_in_path, notice: "Signed out"
  end

  private

  def render_invalid_credentials
    respond_to do |format|
      format.html do
        @page_title = "Sign in · Skycom"
        render_mobile_shell(
          json_url: mobile_sign_in_path(format: :json),
          action: "new",
          status: :unprocessable_content,
          data: {
            errors: [ "Invalid email or password" ].to_json,
            values: { email: @email }.to_json
          }
        )
      end
      format.any { head :unprocessable_content }
    end
  end

  def redirect_to_mobile_home_for(user, **options)
    employee = mobile_employee_for(user)

    if employee
      session[:mobile_company_id] = employee.company_id
      redirect_to mobile_company_home_path(employee.company), **options
    else
      redirect_to mobile_sign_in_path, **options
    end
  end

  def mobile_employee_for(user)
    employees = user.employees.includes(:company)
    employees.find_by(company_id: session[:mobile_company_id]) || employees.first
  end
end

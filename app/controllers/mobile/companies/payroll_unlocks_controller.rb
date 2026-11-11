# frozen_string_literal: true

# Mobile::Companies::PayrollUnlocksController — Shell-First password gate for
# the payroll screen. The form posts natively; a wrong password re-renders the
# same shell with data-errors so the JS form shows it inline.
# Serves Stimulus: Mobile_Companies_PayrollUnlocks_NewController
# Endpoints: GET/POST /mobile/companies/:company_id/payroll/unlock(.json)
# Docs: docs/MOBILE.md §2-§4
class Mobile::Companies::PayrollUnlocksController < Mobile::Companies::BaseController
  # How long one password confirmation keeps the payroll screen accessible.
  MOBILE_PAYROLL_UNLOCK_WINDOW = 5.minutes

  def new
    respond_to do |format|
      format.html do
        @page_title = "Payroll Access"
        render_mobile_shell(json_url: unlock_json_url)
      end
      format.json do
        render json: {
          month: params[:month].presence,
          employee: { name: @employee.name },
          company: { id: @company.id }
        }
      end
    end
  end

  def create
    session.delete(:mobile_payroll_unlock_company_id)
    session.delete(:mobile_payroll_unlock_expires_at)

    unless current_user.authenticate(params[:password].to_s)
      render_unlock_error
      return
    end

    session[:mobile_payroll_unlock_company_id] = @company.id
    session[:mobile_payroll_unlock_expires_at] = MOBILE_PAYROLL_UNLOCK_WINDOW.from_now.to_i

    redirect_to mobile_company_payroll_path(@company, month: params[:month].presence)
  end

  private

  def render_unlock_error
    respond_to do |format|
      format.html do
        @page_title = "Payroll Access"
        render_mobile_shell(
          json_url: unlock_json_url,
          action: "new",
          status: :unprocessable_content,
          data: { errors: [ "Incorrect password" ].to_json }
        )
      end
      format.any { head :unprocessable_content }
    end
  end

  def unlock_json_url
    mobile_company_payroll_unlock_path(
      @company,
      month: params[:month].presence,
      format: :json
    )
  end
end

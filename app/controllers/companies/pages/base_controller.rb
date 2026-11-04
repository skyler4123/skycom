# frozen_string_literal: true

# Companies::Pages::BaseController — shared shell for purpose-specific operation
# pages. Resolves the company Page, its active location appointment, and the
# access gate before the subclass renders its payload.
# Serves Stimulus: Companies_Pages_<Type>_ShowController (via subclasses)
# Docs: docs/OPERATING_PAGES.md
class Companies::Pages::BaseController < Companies::ApplicationController
  before_action :set_page
  before_action :set_appointment
  before_action :authorize_page_roles!

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          page: PageSerializer.page(@page),
          appointment: PageSerializer.appointment(@appointment, employee: current_employee),
          config: effective_config
        }.merge(operation_payload)
      end
    end
  end

  private

  def expected_page_type
    raise NotImplementedError, "#{self.class} must define #expected_page_type"
  end

  def set_page
    @page = current_company.pages.find_by!(id: params[:page_id], page_type: expected_page_type)
    @operation_page = @page
  end

  def set_appointment
    @appointment = Pages::AppointmentResolver.call(
      company: current_company,
      page: @page,
      employee: current_employee,
      branch_id: params[:branch_id],
      warehouse_id: params[:warehouse_id]
    )

    return render_operation_error("No active page appointment found for this location.") unless @appointment
    render_operation_error("This page appointment is inactive.") unless @appointment.workflow_status_active?
  end

  def authorize_page_roles!
    return if @page.accessible_by?(current_employee)

    render_operation_error("You do not have access to this page.", status: :forbidden)
  end

  def effective_config
    @effective_config ||= @page.config_for(@appointment)
  end

  def operation_payload
    { coming_soon: true }
  end

  def render_operation_error(message, status: :unprocessable_content)
    respond_to do |format|
      format.html { redirect_to company_pages_path(current_company), alert: message }
      format.json { render json: { errors: [ message ] }, status: status }
    end
  end
end

# frozen_string_literal: true

# Companies::PageConfigsController — company-wide Page configuration.
# Pages are seeded, never created here. Update permits metadata only; the Page
# metadata wins over every appointment's metadata when effective config is built.
# Serves Stimulus: Companies_PageConfigs_IndexController (index, update modal)
# Endpoints: GET /companies/:company_id/page_configs, PATCH /companies/:company_id/page_configs/:id
# Docs: docs/OPERATING_PAGES.md
class Companies::PageConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        pages = current_company.pages
          .includes(:branch_page_appointments, :page_warehouse_appointments)
          .order(:page_type)

        render json: {
          page_configs: pages.map { |page| format_page_config(page) },
          roles: current_company.roles.order(:name).map { |role| { id: role.id, name: role.name } }
        }
      end
    end
  end

  def update
    page = current_company.pages.find(params[:id])

    if page.update(page_config_params)
      respond_to do |format|
        format.html { redirect_to company_page_configs_path(current_company), notice: "Page config updated." }
        format.json do
          render json: {
            page: PageSerializer.page(page),
            message: "Page config updated."
          }
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to company_page_configs_path(current_company),
            alert: page.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: page.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def page_config_params
    raw = params.require(:page).permit!
    return {} unless raw.key?(:metadata)

    metadata = raw[:metadata]
    metadata = metadata.to_unsafe_h if metadata.respond_to?(:to_unsafe_h)
    { metadata: metadata }
  end

  def format_page_config(page)
    PageSerializer.page(page).merge(
      branch_appointment_count: page.branch_page_appointments.size,
      page_warehouse_appointment_count: page.page_warehouse_appointments.size
    )
  end
end

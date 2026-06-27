# app/controllers/companies/dashboards_controller.rb

class Companies::DashboardsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          company: format_company(current_company),
          counts: {
            products:  count_by_category(current_company.products),
            stocks:    count_by_category(current_company.stocks),
            services:  count_by_category(current_company.services),
            orders:    count_by_category(current_company.orders),
            employees: count_by_category(current_company.employees)
          }
        }
      end
    end
  end

  private

  def format_company(company)
    company.as_json(only: %i[
      id name description code business_type ownership_type
      currency_code timezone lifecycle_status workflow_status
      registration_number vat_id tax_id email phone_number website
      address_line_1 city postal_code country_code
      employee_count fiscal_year_end_month created_at
    ]).merge(
      owner: company.user&.as_json(only: %i[id email first_name last_name])
    )
  end

  def count_by_category(scope)
    scope.joins(:category).group("categories.name").count
  end
end

# app/controllers/companies/dashboards_controller.rb

class Companies::DashboardsController < Companies::ApplicationController
  def index
    credit_warning = deduct_dashboard_credits

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
          },
          credit_warning: credit_warning,
          wallet: { credit_balance: current_company.company_wallet.credit_balance, currency: current_company.currency }
        }
      end
    end
  end

  private

  def deduct_dashboard_credits
    wallet = current_company.company_wallet
    return nil unless wallet

    cost = CREDIT_USAGE_RATES[:access_dashboard]
    wallet.deduct_credits!(amount: cost, description: "Dashboard access", action_type: "access_dashboard")
    current_company.record_credit_usage!(cost)
    nil
  rescue CompanyWallet::InsufficientCreditsError => e
    e.message
  end

  def format_company(company)
    company.as_json(only: %i[
      id name description code business_type ownership_type
      currency timezone lifecycle_status workflow_status
      registration_number vat_id tax_id email phone_number website
      address_line_1 city postal_code country
      employee_count fiscal_year_end_month created_at
    ]).merge(
      owner: company.user&.as_json(only: %i[id email first_name last_name])
    )
  end

  def count_by_category(scope)
    scope.joins(:category).group("categories.name").count
  end
end

# app/controllers/companies/dashboards_controller.rb

class Companies::DashboardsController < Companies::ApplicationController
  # Credit deduction is handled by the after_action filter — never inline.
  deduct_credits_for :index, with: Deduct::Companies::Dashboards::IndexService

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
          },
          wallet: format_wallet(current_company.company_wallet)
        }
      end
    end
  end

  private

  def format_wallet(wallet)
    {
      main_credit_balance: wallet&.main_credit_balance || 0,
      promo_credit_balance: wallet&.promo_credit_balance || 0,
      debt_credit_balance: wallet&.debt_credit_balance || 0,
      currency: current_company.currency
    }
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

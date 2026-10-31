# app/controllers/admin/company_credits_controller.rb
#
# Admin view of all companies' credit wallets (Shell-First). Global scope —
# there is NO current_company here; Admin::ApplicationController gates on
# super_admin/admin instead of Pundit. Plain DB search/filter (no Meilisearch,
# Admin precedent: company_tickets#index).
# Serves Stimulus: Admin_CompanyCredits_IndexController (wallet JSON + filters)
# Endpoints: GET /admin/company_credits(.json)
# Docs: docs/superpowers/specs/2026-10-12-admin-promo-credits-design.md
class Admin::CompanyCreditsController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = Company.includes(:company_wallet, :user, :employees).order(created_at: :desc)
        scope = scope.where("companies.name ILIKE :q OR companies.code ILIKE :q OR companies.email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
        scope = scope.where(country: params[:country]) if params[:country].present?
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        if params[:promo_min].present? || params[:promo_max].present?
          scope = scope.joins(:company_wallet)
          scope = scope.where("company_wallets.promo_credit_balance >= ?", params[:promo_min].to_i) if params[:promo_min].present?
          scope = scope.where("company_wallets.promo_credit_balance <= ?", params[:promo_max].to_i) if params[:promo_max].present?
        end

        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: {
          company_credits: @results.map { |c| format_credit(c) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_credit(company)
    wallet = company.company_wallet
    company.as_json(only: [
      :id, :name, :code, :country, :business_type, :email, :employee_count, :created_at
    ]).merge(
      main_credit_balance: wallet&.main_credit_balance || 0,
      promo_credit_balance: wallet&.promo_credit_balance || 0,
      total_credit_balance: wallet ? wallet.main_credit_balance + wallet.promo_credit_balance : 0,
      owner_name: company.employees.find { |e| e.business_type == "owner" }&.name || company.user&.name
    )
  end
end

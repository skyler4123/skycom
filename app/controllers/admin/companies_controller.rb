# app/controllers/admin/companies_controller.rb

class Admin::CompaniesController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = Company.all
        @pagy, @companies_results = pagy(:offset, scope.order(created_at: :desc), jsonapi: true)

        render json: {
          companies: format_companies(@companies_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    company = Company.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company: format_company(company) } }
    end
  end

  private

  def format_company(company)
    company.as_json(only: [
      :id, :name, :description, :code,
      :business_type, :lifecycle_status, :workflow_status,
      :ownership_type, :currency_code, :timezone,
      :email, :phone_number, :website,
      :city, :country_code, :employee_count,
      :registration_number, :vat_id, :tax_id,
      :created_at, :updated_at
    ]).merge(
      user: company.user&.as_json(only: [ :id, :name, :email ])
    )
  end

  def format_companies(companies)
    companies.map { |c| format_company(c) }
  end
end

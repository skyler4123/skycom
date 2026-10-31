class CompaniesController < ApplicationController
  # Serves Stimulus: companies--new (company creation page renders its form client-side),
  #   companies--show, companies--edit (Company pages under Settings group render client-side)
  # Endpoints: GET /companies/new (new) — Shell-First shell; POST /companies (create) — master-account
  #   (User#can_create_company?) only; GET /companies/:id (show) + GET /companies/:id/edit (edit) +
  #   PATCH /companies/:id (update) — company owner only
  before_action :authorize_company_owner!, only: %i[show edit update]
  before_action :authorize_company_creator!, only: %i[new create]

  # Company settings are also blocked while suspended; creating a new company
  # stays available so the owner can recover elsewhere.
  include Companies::SuspendedCompanyConcern
  skip_before_action :block_suspended_company, only: %i[new create]

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def create
    company = current_user.companies.build(company_params)

    if company.save
      current_user.touch
      respond_to do |format|
        format.html { redirect_to company_dashboards_path(company), notice: "Company created successfully!" }
        format.json { render json: { company: company, message: "Company created successfully" }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: company.errors.full_messages.to_sentence }
        format.json { render json: { errors: company.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company: format_company(@company) } }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company: format_company(@company) } }
    end
  end

  def update
    if @company.update(company_update_params)
      respond_to do |format|
        format.html { redirect_to company_path(@company), notice: "Company updated successfully." }
        format.json { render json: { company: format_company(@company), message: "Company updated successfully." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_company_path(@company), alert: @company.errors.full_messages.to_sentence }
        format.json { render json: { errors: @company.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  # The suspension concern reads current_company; this controller loads the
  # record into @company via authorize_company_owner!.
  def current_company
    @company
  end

  def authorize_company_owner!
    @company = Company.find(params[:id])
    employee = Employee.find_by(user: current_user, company: @company)
    return if employee&.owner_role?

    respond_to do |format|
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_path)
      end
      format.json do
        render json: { errors: [ "You are not authorized to perform this action." ] }, status: :forbidden
      end
    end
  end

  # New Company is a master-account (owner) flow — see User#can_create_company?.
  def authorize_company_creator!
    return if current_user.can_create_company?

    respond_to do |format|
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_path)
      end
      format.json do
        render json: { errors: [ "You are not authorized to perform this action." ] }, status: :forbidden
      end
    end
  end

  def format_company(company)
    company.as_json(only: [
      :id, :name, :description, :email, :phone_number, :website,
      :timezone, :currency, :business_type, :country
    ])
  end

  def company_params
    params.require(:company).permit(:name, :business_type, :country)
  end

  def company_update_params
    params.require(:company).permit(:name, :description, :email, :phone_number, :website, :timezone, :currency)
  end
end

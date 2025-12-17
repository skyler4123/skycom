class CompanyGroupsController < ApplicationController
  before_action :set_company_group, only: %i[ show edit update destroy ]

  # GET /company_groups or /company_groups.json
  def index
    @company_groups = CompanyGroup.all
  end

  # GET /company_groups/1 or /company_groups/1.json
  def show
  end

  # GET /company_groups/new
  def new
    # @company_group = CompanyGroup.new
    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end

  # GET /company_groups/1/edit
  def edit
  end

  # POST /company_groups or /company_groups.json
  def create
    debugger
    return
    @company_group = CompanyGroup.new(company_group_params)
    @company_group.user = Current.user

    respond_to do |format|
      if @company_group.save
        format.html { redirect_to @company_group, notice: "Company group was successfully created." }
        format.json { render :show, status: :created, location: @company_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @company_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /company_groups/1 or /company_groups/1.json
  def update
    respond_to do |format|
      if @company_group.update(company_group_params)
        format.html { redirect_to @company_group, notice: "Company group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @company_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @company_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /company_groups/1 or /company_groups/1.json
  def destroy
    @company_group.destroy!

    respond_to do |format|
      format.html { redirect_to company_groups_path, notice: "Company group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_group
      @company_group = CompanyGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def company_group_params
      params.expect(company_group: [ :user_id, :name, :description, :code, :status, :ownership_type, :business_type, :currency, :registration_number, :vat_id, :address_line_1, :city, :postal_code, :country, :email, :phone_number, :website, :employee_count, :fiscal_year_end_month, :discarded_at, :timezone ])
    end
end

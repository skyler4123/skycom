class BranchesController < ApplicationController
  before_action :set_company, only: %i[ show edit update destroy ]

  # GET /branches or /branches.json
  def index
    @branches = Company.all
  end

  # GET /branches/1 or /branches/1.json
  def show
  end

  # GET /branches/new
  def new
    @company = Company.new
  end

  # GET /branches/1/edit
  def edit
  end

  # POST /branches or /branches.json
  def create
    @company = Company.new(company_params)

    respond_to do |format|
      if @branch.save
        format.html { redirect_to @company, notice: "Company was successfully created." }
        format.json { render :show, status: :created, location: @company }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @branch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /branches/1 or /branches/1.json
  def update
    respond_to do |format|
      if @branch.update(company_params)
        format.html { redirect_to @company, notice: "Company was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @branch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /branches/1 or /branches/1.json
  def destroy
    @branch.destroy!

    respond_to do |format|
      format.html { redirect_to branches_path, notice: "Company was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company
      @company = Company.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def company_params
      params.expect(branch: [ :company_group_id, :parent_company_id, :name, :description, :code, :status, :ownership_type, :business_type, :currency_code, :registration_number, :vat_id, :address_line_1, :city, :postal_code, :country, :email, :phone_number, :website, :employee_count, :fiscal_year_end_month, :discarded_at ])
    end
end

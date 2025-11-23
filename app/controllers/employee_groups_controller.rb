class EmployeeGroupsController < ApplicationController
  before_action :set_employee_group, only: %i[ show edit update destroy ]

  # GET /employee_groups or /employee_groups.json
  def index
    @employee_groups = EmployeeGroup.all
  end

  # GET /employee_groups/1 or /employee_groups/1.json
  def show
  end

  # GET /employee_groups/new
  def new
    @employee_group = EmployeeGroup.new
  end

  # GET /employee_groups/1/edit
  def edit
  end

  # POST /employee_groups or /employee_groups.json
  def create
    @employee_group = EmployeeGroup.new(employee_group_params)

    respond_to do |format|
      if @employee_group.save
        format.html { redirect_to @employee_group, notice: "Employee group was successfully created." }
        format.json { render :show, status: :created, location: @employee_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @employee_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_groups/1 or /employee_groups/1.json
  def update
    respond_to do |format|
      if @employee_group.update(employee_group_params)
        format.html { redirect_to @employee_group, notice: "Employee group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @employee_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @employee_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_groups/1 or /employee_groups/1.json
  def destroy
    @employee_group.destroy!

    respond_to do |format|
      format.html { redirect_to employee_groups_path, notice: "Employee group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_group
      @employee_group = EmployeeGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def employee_group_params
      params.expect(employee_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

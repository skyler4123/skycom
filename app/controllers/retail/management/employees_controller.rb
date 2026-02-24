class Retail::Management::EmployeesController < Retail::Management::ApplicationController
  before_action :set_employee, only: %i[ show edit update destroy ]

  # GET /retail/:retail_id/management/employees
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @employees = @retail.cached_employees
        render json: { employees: @employees }
      end
    end
  end

  # GET /retail/:retail_id/management/employees/new
  def new
    @employee = Employee.new
  end

  # POST /retail/:retail_id/management/employees
  def create
    @employee = Employee.new(employee_params)
    @employee.company_group = @retail
    @employee.company = @retail.companies.first # Default to first company, can be made configurable

    respond_to do |format|
      if @employee.save
        format.html { redirect_to retail_management_employees_path(@retail), notice: "Employee was successfully created." }
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /retail/:retail_id/management/employees/:id
  def show
  end

  # GET /retail/:retail_id/management/employees/:id/edit
  def edit
  end

  # PATCH/PUT /retail/:retail_id/management/employees/:id
  def update
    respond_to do |format|
      if @employee.update(employee_params)
        format.html { redirect_to retail_management_employees_path(@retail), notice: "Employee was successfully updated." }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /retail/:retail_id/management/employees/:id
  def destroy
    @employee.destroy!

    respond_to do |format|
      format.html { redirect_to retail_management_employees_path(@retail), notice: "Employee was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_employee
    @employee = Employee.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def employee_params
    params.require(:employee).permit(:name, :description, :code, :business_type, :category_id)
  end
end

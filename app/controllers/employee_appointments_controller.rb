class EmployeeAppointmentsController < ApplicationController
  before_action :set_employee_appointment, only: %i[ show edit update destroy ]

  # GET /employee_appointments or /employee_appointments.json
  def index
    @employee_appointments = EmployeeAppointment.all
  end

  # GET /employee_appointments/1 or /employee_appointments/1.json
  def show
  end

  # GET /employee_appointments/new
  def new
    @employee_appointment = EmployeeAppointment.new
  end

  # GET /employee_appointments/1/edit
  def edit
  end

  # POST /employee_appointments or /employee_appointments.json
  def create
    @employee_appointment = EmployeeAppointment.new(employee_appointment_params)

    respond_to do |format|
      if @employee_appointment.save
        format.html { redirect_to @employee_appointment, notice: "Employee appointment was successfully created." }
        format.json { render :show, status: :created, location: @employee_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @employee_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_appointments/1 or /employee_appointments/1.json
  def update
    respond_to do |format|
      if @employee_appointment.update(employee_appointment_params)
        format.html { redirect_to @employee_appointment, notice: "Employee appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @employee_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @employee_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_appointments/1 or /employee_appointments/1.json
  def destroy
    @employee_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to employee_appointments_path, notice: "Employee appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_appointment
      @employee_appointment = EmployeeAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def employee_appointment_params
      params.expect(employee_appointment: [ :employee_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code ])
    end
end

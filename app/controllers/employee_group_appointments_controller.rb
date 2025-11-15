class EmployeeGroupAppointmentsController < ApplicationController
  before_action :set_employee_group_appointment, only: %i[ show edit update destroy ]

  # GET /employee_group_appointments or /employee_group_appointments.json
  def index
    @employee_group_appointments = EmployeeGroupAppointment.all
  end

  # GET /employee_group_appointments/1 or /employee_group_appointments/1.json
  def show
  end

  # GET /employee_group_appointments/new
  def new
    @employee_group_appointment = EmployeeGroupAppointment.new
  end

  # GET /employee_group_appointments/1/edit
  def edit
  end

  # POST /employee_group_appointments or /employee_group_appointments.json
  def create
    @employee_group_appointment = EmployeeGroupAppointment.new(employee_group_appointment_params)

    respond_to do |format|
      if @employee_group_appointment.save
        format.html { redirect_to @employee_group_appointment, notice: "Employee group appointment was successfully created." }
        format.json { render :show, status: :created, location: @employee_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @employee_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_group_appointments/1 or /employee_group_appointments/1.json
  def update
    respond_to do |format|
      if @employee_group_appointment.update(employee_group_appointment_params)
        format.html { redirect_to @employee_group_appointment, notice: "Employee group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @employee_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @employee_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_group_appointments/1 or /employee_group_appointments/1.json
  def destroy
    @employee_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to employee_group_appointments_path, notice: "Employee group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_group_appointment
      @employee_group_appointment = EmployeeGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def employee_group_appointment_params
      params.expect(employee_group_appointment: [ :employee_group_id, :appoint_to_id, :appoint_to_type, :name, :description ])
    end
end

class RoleAppointmentsController < ApplicationController
  before_action :set_role_appointment, only: %i[ show edit update destroy ]

  # GET /role_appointments or /role_appointments.json
  def index
    @role_appointments = RoleAppointment.all
  end

  # GET /role_appointments/1 or /role_appointments/1.json
  def show
  end

  # GET /role_appointments/new
  def new
    @role_appointment = RoleAppointment.new
  end

  # GET /role_appointments/1/edit
  def edit
  end

  # POST /role_appointments or /role_appointments.json
  def create
    @role_appointment = RoleAppointment.new(role_appointment_params)

    respond_to do |format|
      if @role_appointment.save
        format.html { redirect_to @role_appointment, notice: "Role appointment was successfully created." }
        format.json { render :show, status: :created, location: @role_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @role_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /role_appointments/1 or /role_appointments/1.json
  def update
    respond_to do |format|
      if @role_appointment.update(role_appointment_params)
        format.html { redirect_to @role_appointment, notice: "Role appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @role_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @role_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /role_appointments/1 or /role_appointments/1.json
  def destroy
    @role_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to role_appointments_path, notice: "Role appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role_appointment
      @role_appointment = RoleAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def role_appointment_params
      params.expect(role_appointment: [ :role_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

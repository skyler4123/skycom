class ServiceAppointmentsController < ApplicationController
  before_action :set_service_appointment, only: %i[ show edit update destroy ]

  # GET /service_appointments or /service_appointments.json
  def index
    @service_appointments = ServiceAppointment.all
  end

  # GET /service_appointments/1 or /service_appointments/1.json
  def show
  end

  # GET /service_appointments/new
  def new
    @service_appointment = ServiceAppointment.new
  end

  # GET /service_appointments/1/edit
  def edit
  end

  # POST /service_appointments or /service_appointments.json
  def create
    @service_appointment = ServiceAppointment.new(service_appointment_params)

    respond_to do |format|
      if @service_appointment.save
        format.html { redirect_to @service_appointment, notice: "Service appointment was successfully created." }
        format.json { render :show, status: :created, location: @service_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @service_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /service_appointments/1 or /service_appointments/1.json
  def update
    respond_to do |format|
      if @service_appointment.update(service_appointment_params)
        format.html { redirect_to @service_appointment, notice: "Service appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @service_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @service_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /service_appointments/1 or /service_appointments/1.json
  def destroy
    @service_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to service_appointments_path, notice: "Service appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service_appointment
      @service_appointment = ServiceAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def service_appointment_params
      params.expect(service_appointment: [ :service_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at ])
    end
end

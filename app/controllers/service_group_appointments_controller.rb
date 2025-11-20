class ServiceGroupAppointmentsController < ApplicationController
  before_action :set_service_group_appointment, only: %i[ show edit update destroy ]

  # GET /service_group_appointments or /service_group_appointments.json
  def index
    @service_group_appointments = ServiceGroupAppointment.all
  end

  # GET /service_group_appointments/1 or /service_group_appointments/1.json
  def show
  end

  # GET /service_group_appointments/new
  def new
    @service_group_appointment = ServiceGroupAppointment.new
  end

  # GET /service_group_appointments/1/edit
  def edit
  end

  # POST /service_group_appointments or /service_group_appointments.json
  def create
    @service_group_appointment = ServiceGroupAppointment.new(service_group_appointment_params)

    respond_to do |format|
      if @service_group_appointment.save
        format.html { redirect_to @service_group_appointment, notice: "Service group appointment was successfully created." }
        format.json { render :show, status: :created, location: @service_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @service_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /service_group_appointments/1 or /service_group_appointments/1.json
  def update
    respond_to do |format|
      if @service_group_appointment.update(service_group_appointment_params)
        format.html { redirect_to @service_group_appointment, notice: "Service group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @service_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @service_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /service_group_appointments/1 or /service_group_appointments/1.json
  def destroy
    @service_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to service_group_appointments_path, notice: "Service group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service_group_appointment
      @service_group_appointment = ServiceGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def service_group_appointment_params
      params.expect(service_group_appointment: [ :service_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at ])
    end
end

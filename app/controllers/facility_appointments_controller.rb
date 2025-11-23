class FacilityAppointmentsController < ApplicationController
  before_action :set_facility_appointment, only: %i[ show edit update destroy ]

  # GET /facility_appointments or /facility_appointments.json
  def index
    @facility_appointments = FacilityAppointment.all
  end

  # GET /facility_appointments/1 or /facility_appointments/1.json
  def show
  end

  # GET /facility_appointments/new
  def new
    @facility_appointment = FacilityAppointment.new
  end

  # GET /facility_appointments/1/edit
  def edit
  end

  # POST /facility_appointments or /facility_appointments.json
  def create
    @facility_appointment = FacilityAppointment.new(facility_appointment_params)

    respond_to do |format|
      if @facility_appointment.save
        format.html { redirect_to @facility_appointment, notice: "Facility appointment was successfully created." }
        format.json { render :show, status: :created, location: @facility_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @facility_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /facility_appointments/1 or /facility_appointments/1.json
  def update
    respond_to do |format|
      if @facility_appointment.update(facility_appointment_params)
        format.html { redirect_to @facility_appointment, notice: "Facility appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @facility_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @facility_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /facility_appointments/1 or /facility_appointments/1.json
  def destroy
    @facility_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to facility_appointments_path, notice: "Facility appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_facility_appointment
      @facility_appointment = FacilityAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def facility_appointment_params
      params.expect(facility_appointment: [ :facility_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

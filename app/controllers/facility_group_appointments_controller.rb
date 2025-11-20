class FacilityGroupAppointmentsController < ApplicationController
  before_action :set_facility_group_appointment, only: %i[ show edit update destroy ]

  # GET /facility_group_appointments or /facility_group_appointments.json
  def index
    @facility_group_appointments = FacilityGroupAppointment.all
  end

  # GET /facility_group_appointments/1 or /facility_group_appointments/1.json
  def show
  end

  # GET /facility_group_appointments/new
  def new
    @facility_group_appointment = FacilityGroupAppointment.new
  end

  # GET /facility_group_appointments/1/edit
  def edit
  end

  # POST /facility_group_appointments or /facility_group_appointments.json
  def create
    @facility_group_appointment = FacilityGroupAppointment.new(facility_group_appointment_params)

    respond_to do |format|
      if @facility_group_appointment.save
        format.html { redirect_to @facility_group_appointment, notice: "Facility group appointment was successfully created." }
        format.json { render :show, status: :created, location: @facility_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @facility_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /facility_group_appointments/1 or /facility_group_appointments/1.json
  def update
    respond_to do |format|
      if @facility_group_appointment.update(facility_group_appointment_params)
        format.html { redirect_to @facility_group_appointment, notice: "Facility group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @facility_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @facility_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /facility_group_appointments/1 or /facility_group_appointments/1.json
  def destroy
    @facility_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to facility_group_appointments_path, notice: "Facility group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_facility_group_appointment
      @facility_group_appointment = FacilityGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def facility_group_appointment_params
      params.expect(facility_group_appointment: [ :facility_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

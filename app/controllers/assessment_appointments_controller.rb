class AssessmentAppointmentsController < ApplicationController
  before_action :set_assessment_appointment, only: %i[ show edit update destroy ]

  # GET /assessment_appointments or /assessment_appointments.json
  def index
    @assessment_appointments = AssessmentAppointment.all
  end

  # GET /assessment_appointments/1 or /assessment_appointments/1.json
  def show
  end

  # GET /assessment_appointments/new
  def new
    @assessment_appointment = AssessmentAppointment.new
  end

  # GET /assessment_appointments/1/edit
  def edit
  end

  # POST /assessment_appointments or /assessment_appointments.json
  def create
    @assessment_appointment = AssessmentAppointment.new(assessment_appointment_params)

    respond_to do |format|
      if @assessment_appointment.save
        format.html { redirect_to @assessment_appointment, notice: "Assessment appointment was successfully created." }
        format.json { render :show, status: :created, location: @assessment_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @assessment_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /assessment_appointments/1 or /assessment_appointments/1.json
  def update
    respond_to do |format|
      if @assessment_appointment.update(assessment_appointment_params)
        format.html { redirect_to @assessment_appointment, notice: "Assessment appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @assessment_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @assessment_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assessment_appointments/1 or /assessment_appointments/1.json
  def destroy
    @assessment_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to assessment_appointments_path, notice: "Assessment appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_assessment_appointment
      @assessment_appointment = AssessmentAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def assessment_appointment_params
      params.expect(assessment_appointment: [ :assessment_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

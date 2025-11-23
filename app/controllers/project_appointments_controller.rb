class ProjectAppointmentsController < ApplicationController
  before_action :set_project_appointment, only: %i[ show edit update destroy ]

  # GET /project_appointments or /project_appointments.json
  def index
    @project_appointments = ProjectAppointment.all
  end

  # GET /project_appointments/1 or /project_appointments/1.json
  def show
  end

  # GET /project_appointments/new
  def new
    @project_appointment = ProjectAppointment.new
  end

  # GET /project_appointments/1/edit
  def edit
  end

  # POST /project_appointments or /project_appointments.json
  def create
    @project_appointment = ProjectAppointment.new(project_appointment_params)

    respond_to do |format|
      if @project_appointment.save
        format.html { redirect_to @project_appointment, notice: "Project appointment was successfully created." }
        format.json { render :show, status: :created, location: @project_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_appointments/1 or /project_appointments/1.json
  def update
    respond_to do |format|
      if @project_appointment.update(project_appointment_params)
        format.html { redirect_to @project_appointment, notice: "Project appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @project_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_appointments/1 or /project_appointments/1.json
  def destroy
    @project_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to project_appointments_path, notice: "Project appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_appointment
      @project_appointment = ProjectAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def project_appointment_params
      params.expect(project_appointment: [ :project_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

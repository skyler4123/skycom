class ProjectGroupAppointmentsController < ApplicationController
  before_action :set_project_group_appointment, only: %i[ show edit update destroy ]

  # GET /project_group_appointments or /project_group_appointments.json
  def index
    @project_group_appointments = ProjectGroupAppointment.all
  end

  # GET /project_group_appointments/1 or /project_group_appointments/1.json
  def show
  end

  # GET /project_group_appointments/new
  def new
    @project_group_appointment = ProjectGroupAppointment.new
  end

  # GET /project_group_appointments/1/edit
  def edit
  end

  # POST /project_group_appointments or /project_group_appointments.json
  def create
    @project_group_appointment = ProjectGroupAppointment.new(project_group_appointment_params)

    respond_to do |format|
      if @project_group_appointment.save
        format.html { redirect_to @project_group_appointment, notice: "Project group appointment was successfully created." }
        format.json { render :show, status: :created, location: @project_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_group_appointments/1 or /project_group_appointments/1.json
  def update
    respond_to do |format|
      if @project_group_appointment.update(project_group_appointment_params)
        format.html { redirect_to @project_group_appointment, notice: "Project group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @project_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_group_appointments/1 or /project_group_appointments/1.json
  def destroy
    @project_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to project_group_appointments_path, notice: "Project group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_group_appointment
      @project_group_appointment = ProjectGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def project_group_appointment_params
      params.expect(project_group_appointment: [ :project_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

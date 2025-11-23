class TaskAppointmentsController < ApplicationController
  before_action :set_task_appointment, only: %i[ show edit update destroy ]

  # GET /task_appointments or /task_appointments.json
  def index
    @task_appointments = TaskAppointment.all
  end

  # GET /task_appointments/1 or /task_appointments/1.json
  def show
  end

  # GET /task_appointments/new
  def new
    @task_appointment = TaskAppointment.new
  end

  # GET /task_appointments/1/edit
  def edit
  end

  # POST /task_appointments or /task_appointments.json
  def create
    @task_appointment = TaskAppointment.new(task_appointment_params)

    respond_to do |format|
      if @task_appointment.save
        format.html { redirect_to @task_appointment, notice: "Task appointment was successfully created." }
        format.json { render :show, status: :created, location: @task_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /task_appointments/1 or /task_appointments/1.json
  def update
    respond_to do |format|
      if @task_appointment.update(task_appointment_params)
        format.html { redirect_to @task_appointment, notice: "Task appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @task_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /task_appointments/1 or /task_appointments/1.json
  def destroy
    @task_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to task_appointments_path, notice: "Task appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task_appointment
      @task_appointment = TaskAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def task_appointment_params
      params.expect(task_appointment: [ :task_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

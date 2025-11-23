class PolicyAppointmentsController < ApplicationController
  before_action :set_policy_appointment, only: %i[ show edit update destroy ]

  # GET /policy_appointments or /policy_appointments.json
  def index
    @policy_appointments = PolicyAppointment.all
  end

  # GET /policy_appointments/1 or /policy_appointments/1.json
  def show
  end

  # GET /policy_appointments/new
  def new
    @policy_appointment = PolicyAppointment.new
  end

  # GET /policy_appointments/1/edit
  def edit
  end

  # POST /policy_appointments or /policy_appointments.json
  def create
    @policy_appointment = PolicyAppointment.new(policy_appointment_params)

    respond_to do |format|
      if @policy_appointment.save
        format.html { redirect_to @policy_appointment, notice: "Policy appointment was successfully created." }
        format.json { render :show, status: :created, location: @policy_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @policy_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /policy_appointments/1 or /policy_appointments/1.json
  def update
    respond_to do |format|
      if @policy_appointment.update(policy_appointment_params)
        format.html { redirect_to @policy_appointment, notice: "Policy appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @policy_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @policy_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /policy_appointments/1 or /policy_appointments/1.json
  def destroy
    @policy_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to policy_appointments_path, notice: "Policy appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_policy_appointment
      @policy_appointment = PolicyAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def policy_appointment_params
      params.expect(policy_appointment: [ :policy_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

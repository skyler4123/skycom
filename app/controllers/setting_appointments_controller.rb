class SettingAppointmentsController < ApplicationController
  before_action :set_setting_appointment, only: %i[ show edit update destroy ]

  # GET /setting_appointments or /setting_appointments.json
  def index
    @setting_appointments = SettingAppointment.all
  end

  # GET /setting_appointments/1 or /setting_appointments/1.json
  def show
  end

  # GET /setting_appointments/new
  def new
    @setting_appointment = SettingAppointment.new
  end

  # GET /setting_appointments/1/edit
  def edit
  end

  # POST /setting_appointments or /setting_appointments.json
  def create
    @setting_appointment = SettingAppointment.new(setting_appointment_params)

    respond_to do |format|
      if @setting_appointment.save
        format.html { redirect_to @setting_appointment, notice: "Setting appointment was successfully created." }
        format.json { render :show, status: :created, location: @setting_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @setting_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /setting_appointments/1 or /setting_appointments/1.json
  def update
    respond_to do |format|
      if @setting_appointment.update(setting_appointment_params)
        format.html { redirect_to @setting_appointment, notice: "Setting appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @setting_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @setting_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /setting_appointments/1 or /setting_appointments/1.json
  def destroy
    @setting_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to setting_appointments_path, notice: "Setting appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting_appointment
      @setting_appointment = SettingAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def setting_appointment_params
      params.expect(setting_appointment: [ :setting_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

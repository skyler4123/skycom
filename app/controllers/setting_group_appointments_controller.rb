class SettingGroupAppointmentsController < ApplicationController
  before_action :set_setting_group_appointment, only: %i[ show edit update destroy ]

  # GET /setting_group_appointments or /setting_group_appointments.json
  def index
    @setting_group_appointments = SettingGroupAppointment.all
  end

  # GET /setting_group_appointments/1 or /setting_group_appointments/1.json
  def show
  end

  # GET /setting_group_appointments/new
  def new
    @setting_group_appointment = SettingGroupAppointment.new
  end

  # GET /setting_group_appointments/1/edit
  def edit
  end

  # POST /setting_group_appointments or /setting_group_appointments.json
  def create
    @setting_group_appointment = SettingGroupAppointment.new(setting_group_appointment_params)

    respond_to do |format|
      if @setting_group_appointment.save
        format.html { redirect_to @setting_group_appointment, notice: "Setting group appointment was successfully created." }
        format.json { render :show, status: :created, location: @setting_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @setting_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /setting_group_appointments/1 or /setting_group_appointments/1.json
  def update
    respond_to do |format|
      if @setting_group_appointment.update(setting_group_appointment_params)
        format.html { redirect_to @setting_group_appointment, notice: "Setting group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @setting_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @setting_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /setting_group_appointments/1 or /setting_group_appointments/1.json
  def destroy
    @setting_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to setting_group_appointments_path, notice: "Setting group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting_group_appointment
      @setting_group_appointment = SettingGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def setting_group_appointment_params
      params.expect(setting_group_appointment: [ :setting_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

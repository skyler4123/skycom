class NotificationGroupAppointmentsController < ApplicationController
  before_action :set_notification_group_appointment, only: %i[ show edit update destroy ]

  # GET /notification_group_appointments or /notification_group_appointments.json
  def index
    @notification_group_appointments = NotificationGroupAppointment.all
  end

  # GET /notification_group_appointments/1 or /notification_group_appointments/1.json
  def show
  end

  # GET /notification_group_appointments/new
  def new
    @notification_group_appointment = NotificationGroupAppointment.new
  end

  # GET /notification_group_appointments/1/edit
  def edit
  end

  # POST /notification_group_appointments or /notification_group_appointments.json
  def create
    @notification_group_appointment = NotificationGroupAppointment.new(notification_group_appointment_params)

    respond_to do |format|
      if @notification_group_appointment.save
        format.html { redirect_to @notification_group_appointment, notice: "Notification group appointment was successfully created." }
        format.json { render :show, status: :created, location: @notification_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notification_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notification_group_appointments/1 or /notification_group_appointments/1.json
  def update
    respond_to do |format|
      if @notification_group_appointment.update(notification_group_appointment_params)
        format.html { redirect_to @notification_group_appointment, notice: "Notification group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @notification_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notification_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_group_appointments/1 or /notification_group_appointments/1.json
  def destroy
    @notification_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to notification_group_appointments_path, notice: "Notification group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification_group_appointment
      @notification_group_appointment = NotificationGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def notification_group_appointment_params
      params.expect(notification_group_appointment: [ :notification_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

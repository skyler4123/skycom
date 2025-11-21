class NotificationAppointmentsController < ApplicationController
  before_action :set_notification_appointment, only: %i[ show edit update destroy ]

  # GET /notification_appointments or /notification_appointments.json
  def index
    @notification_appointments = NotificationAppointment.all
  end

  # GET /notification_appointments/1 or /notification_appointments/1.json
  def show
  end

  # GET /notification_appointments/new
  def new
    @notification_appointment = NotificationAppointment.new
  end

  # GET /notification_appointments/1/edit
  def edit
  end

  # POST /notification_appointments or /notification_appointments.json
  def create
    @notification_appointment = NotificationAppointment.new(notification_appointment_params)

    respond_to do |format|
      if @notification_appointment.save
        format.html { redirect_to @notification_appointment, notice: "Notification appointment was successfully created." }
        format.json { render :show, status: :created, location: @notification_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notification_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notification_appointments/1 or /notification_appointments/1.json
  def update
    respond_to do |format|
      if @notification_appointment.update(notification_appointment_params)
        format.html { redirect_to @notification_appointment, notice: "Notification appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @notification_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notification_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_appointments/1 or /notification_appointments/1.json
  def destroy
    @notification_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to notification_appointments_path, notice: "Notification appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification_appointment
      @notification_appointment = NotificationAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def notification_appointment_params
      params.expect(notification_appointment: [ :notification_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

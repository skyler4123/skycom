class EventAppointmentsController < ApplicationController
  before_action :set_event_appointment, only: %i[ show edit update destroy ]

  # GET /event_appointments or /event_appointments.json
  def index
    @event_appointments = EventAppointment.all
  end

  # GET /event_appointments/1 or /event_appointments/1.json
  def show
  end

  # GET /event_appointments/new
  def new
    @event_appointment = EventAppointment.new
  end

  # GET /event_appointments/1/edit
  def edit
  end

  # POST /event_appointments or /event_appointments.json
  def create
    @event_appointment = EventAppointment.new(event_appointment_params)

    respond_to do |format|
      if @event_appointment.save
        format.html { redirect_to @event_appointment, notice: "Event appointment was successfully created." }
        format.json { render :show, status: :created, location: @event_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_appointments/1 or /event_appointments/1.json
  def update
    respond_to do |format|
      if @event_appointment.update(event_appointment_params)
        format.html { redirect_to @event_appointment, notice: "Event appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @event_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_appointments/1 or /event_appointments/1.json
  def destroy
    @event_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to event_appointments_path, notice: "Event appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_appointment
      @event_appointment = EventAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_appointment_params
      params.expect(event_appointment: [ :event_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

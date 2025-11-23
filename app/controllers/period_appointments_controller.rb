class PeriodAppointmentsController < ApplicationController
  before_action :set_period_appointment, only: %i[ show edit update destroy ]

  # GET /period_appointments or /period_appointments.json
  def index
    @period_appointments = PeriodAppointment.all
  end

  # GET /period_appointments/1 or /period_appointments/1.json
  def show
  end

  # GET /period_appointments/new
  def new
    @period_appointment = PeriodAppointment.new
  end

  # GET /period_appointments/1/edit
  def edit
  end

  # POST /period_appointments or /period_appointments.json
  def create
    @period_appointment = PeriodAppointment.new(period_appointment_params)

    respond_to do |format|
      if @period_appointment.save
        format.html { redirect_to @period_appointment, notice: "Period appointment was successfully created." }
        format.json { render :show, status: :created, location: @period_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @period_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /period_appointments/1 or /period_appointments/1.json
  def update
    respond_to do |format|
      if @period_appointment.update(period_appointment_params)
        format.html { redirect_to @period_appointment, notice: "Period appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @period_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @period_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /period_appointments/1 or /period_appointments/1.json
  def destroy
    @period_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to period_appointments_path, notice: "Period appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_period_appointment
      @period_appointment = PeriodAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def period_appointment_params
      params.expect(period_appointment: [ :period_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :value ])
    end
end

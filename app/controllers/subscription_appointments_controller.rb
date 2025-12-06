class SubscriptionAppointmentsController < ApplicationController
  before_action :set_subscription_appointment, only: %i[ show edit update destroy ]

  # GET /subscription_appointments or /subscription_appointments.json
  def index
    @subscription_appointments = SubscriptionAppointment.all
  end

  # GET /subscription_appointments/1 or /subscription_appointments/1.json
  def show
  end

  # GET /subscription_appointments/new
  def new
    @subscription_appointment = SubscriptionAppointment.new
  end

  # GET /subscription_appointments/1/edit
  def edit
  end

  # POST /subscription_appointments or /subscription_appointments.json
  def create
    @subscription_appointment = SubscriptionAppointment.new(subscription_appointment_params)

    respond_to do |format|
      if @subscription_appointment.save
        format.html { redirect_to @subscription_appointment, notice: "Subscription appointment was successfully created." }
        format.json { render :show, status: :created, location: @subscription_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscription_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscription_appointments/1 or /subscription_appointments/1.json
  def update
    respond_to do |format|
      if @subscription_appointment.update(subscription_appointment_params)
        format.html { redirect_to @subscription_appointment, notice: "Subscription appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @subscription_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscription_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscription_appointments/1 or /subscription_appointments/1.json
  def destroy
    @subscription_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to subscription_appointments_path, notice: "Subscription appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription_appointment
      @subscription_appointment = SubscriptionAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subscription_appointment_params
      params.expect(subscription_appointment: [ :subscription_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

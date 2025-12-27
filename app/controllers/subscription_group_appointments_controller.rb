class SubscriptionGroupAppointmentsController < ApplicationController
  before_action :set_subscription_group_appointment, only: %i[ show edit update destroy ]

  # GET /subscription_group_appointments or /subscription_group_appointments.json
  def index
    @subscription_group_appointments = SubscriptionGroupAppointment.all
  end

  # GET /subscription_group_appointments/1 or /subscription_group_appointments/1.json
  def show
  end

  # GET /subscription_group_appointments/new
  def new
    @subscription_group_appointment = SubscriptionGroupAppointment.new
  end

  # GET /subscription_group_appointments/1/edit
  def edit
  end

  # POST /subscription_group_appointments or /subscription_group_appointments.json
  def create
    @subscription_group_appointment = SubscriptionGroupAppointment.new(subscription_group_appointment_params)

    respond_to do |format|
      if @subscription_group_appointment.save
        format.html { redirect_to @subscription_group_appointment, notice: "Subscription group appointment was successfully created." }
        format.json { render :show, status: :created, location: @subscription_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscription_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscription_group_appointments/1 or /subscription_group_appointments/1.json
  def update
    respond_to do |format|
      if @subscription_group_appointment.update(subscription_group_appointment_params)
        format.html { redirect_to @subscription_group_appointment, notice: "Subscription group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @subscription_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscription_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscription_group_appointments/1 or /subscription_group_appointments/1.json
  def destroy
    @subscription_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to subscription_group_appointments_path, notice: "Subscription group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription_group_appointment
      @subscription_group_appointment = SubscriptionGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subscription_group_appointment_params
      params.expect(subscription_group_appointment: [ :subscription_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :discarded_at ])
    end
end

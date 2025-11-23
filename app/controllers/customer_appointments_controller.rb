class CustomerAppointmentsController < ApplicationController
  before_action :set_customer_appointment, only: %i[ show edit update destroy ]

  # GET /customer_appointments or /customer_appointments.json
  def index
    @customer_appointments = CustomerAppointment.all
  end

  # GET /customer_appointments/1 or /customer_appointments/1.json
  def show
  end

  # GET /customer_appointments/new
  def new
    @customer_appointment = CustomerAppointment.new
  end

  # GET /customer_appointments/1/edit
  def edit
  end

  # POST /customer_appointments or /customer_appointments.json
  def create
    @customer_appointment = CustomerAppointment.new(customer_appointment_params)

    respond_to do |format|
      if @customer_appointment.save
        format.html { redirect_to @customer_appointment, notice: "Customer appointment was successfully created." }
        format.json { render :show, status: :created, location: @customer_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customer_appointments/1 or /customer_appointments/1.json
  def update
    respond_to do |format|
      if @customer_appointment.update(customer_appointment_params)
        format.html { redirect_to @customer_appointment, notice: "Customer appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customer_appointments/1 or /customer_appointments/1.json
  def destroy
    @customer_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to customer_appointments_path, notice: "Customer appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer_appointment
      @customer_appointment = CustomerAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def customer_appointment_params
      params.expect(customer_appointment: [ :customer_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

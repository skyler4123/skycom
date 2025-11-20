class CustomerGroupAppointmentsController < ApplicationController
  before_action :set_customer_group_appointment, only: %i[ show edit update destroy ]

  # GET /customer_group_appointments or /customer_group_appointments.json
  def index
    @customer_group_appointments = CustomerGroupAppointment.all
  end

  # GET /customer_group_appointments/1 or /customer_group_appointments/1.json
  def show
  end

  # GET /customer_group_appointments/new
  def new
    @customer_group_appointment = CustomerGroupAppointment.new
  end

  # GET /customer_group_appointments/1/edit
  def edit
  end

  # POST /customer_group_appointments or /customer_group_appointments.json
  def create
    @customer_group_appointment = CustomerGroupAppointment.new(customer_group_appointment_params)

    respond_to do |format|
      if @customer_group_appointment.save
        format.html { redirect_to @customer_group_appointment, notice: "Customer group appointment was successfully created." }
        format.json { render :show, status: :created, location: @customer_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customer_group_appointments/1 or /customer_group_appointments/1.json
  def update
    respond_to do |format|
      if @customer_group_appointment.update(customer_group_appointment_params)
        format.html { redirect_to @customer_group_appointment, notice: "Customer group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @customer_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customer_group_appointments/1 or /customer_group_appointments/1.json
  def destroy
    @customer_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to customer_group_appointments_path, notice: "Customer group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer_group_appointment
      @customer_group_appointment = CustomerGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def customer_group_appointment_params
      params.expect(customer_group_appointment: [ :customer_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

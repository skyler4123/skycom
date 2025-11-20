class PaymentMethodAppointmentsController < ApplicationController
  before_action :set_payment_method_appointment, only: %i[ show edit update destroy ]

  # GET /payment_method_appointments or /payment_method_appointments.json
  def index
    @payment_method_appointments = PaymentMethodAppointment.all
  end

  # GET /payment_method_appointments/1 or /payment_method_appointments/1.json
  def show
  end

  # GET /payment_method_appointments/new
  def new
    @payment_method_appointment = PaymentMethodAppointment.new
  end

  # GET /payment_method_appointments/1/edit
  def edit
  end

  # POST /payment_method_appointments or /payment_method_appointments.json
  def create
    @payment_method_appointment = PaymentMethodAppointment.new(payment_method_appointment_params)

    respond_to do |format|
      if @payment_method_appointment.save
        format.html { redirect_to @payment_method_appointment, notice: "Payment method appointment was successfully created." }
        format.json { render :show, status: :created, location: @payment_method_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @payment_method_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payment_method_appointments/1 or /payment_method_appointments/1.json
  def update
    respond_to do |format|
      if @payment_method_appointment.update(payment_method_appointment_params)
        format.html { redirect_to @payment_method_appointment, notice: "Payment method appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @payment_method_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @payment_method_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payment_method_appointments/1 or /payment_method_appointments/1.json
  def destroy
    @payment_method_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to payment_method_appointments_path, notice: "Payment method appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment_method_appointment
      @payment_method_appointment = PaymentMethodAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def payment_method_appointment_params
      params.expect(payment_method_appointment: [ :payment_method_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

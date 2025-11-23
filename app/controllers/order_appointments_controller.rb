class OrderAppointmentsController < ApplicationController
  before_action :set_order_appointment, only: %i[ show edit update destroy ]

  # GET /order_appointments or /order_appointments.json
  def index
    @order_appointments = OrderAppointment.all
  end

  # GET /order_appointments/1 or /order_appointments/1.json
  def show
  end

  # GET /order_appointments/new
  def new
    @order_appointment = OrderAppointment.new
  end

  # GET /order_appointments/1/edit
  def edit
  end

  # POST /order_appointments or /order_appointments.json
  def create
    @order_appointment = OrderAppointment.new(order_appointment_params)

    respond_to do |format|
      if @order_appointment.save
        format.html { redirect_to @order_appointment, notice: "Order appointment was successfully created." }
        format.json { render :show, status: :created, location: @order_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /order_appointments/1 or /order_appointments/1.json
  def update
    respond_to do |format|
      if @order_appointment.update(order_appointment_params)
        format.html { redirect_to @order_appointment, notice: "Order appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @order_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /order_appointments/1 or /order_appointments/1.json
  def destroy
    @order_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to order_appointments_path, notice: "Order appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_appointment
      @order_appointment = OrderAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_appointment_params
      params.expect(order_appointment: [ :order_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :unit_price, :quantity, :total_price, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

class OrderItemAppointmentsController < ApplicationController
  before_action :set_order_item_appointment, only: %i[ show edit update destroy ]

  # GET /order_item_appointments or /order_item_appointments.json
  def index
    @order_item_appointments = OrderItemAppointment.all
  end

  # GET /order_item_appointments/1 or /order_item_appointments/1.json
  def show
  end

  # GET /order_item_appointments/new
  def new
    @order_item_appointment = OrderItemAppointment.new
  end

  # GET /order_item_appointments/1/edit
  def edit
  end

  # POST /order_item_appointments or /order_item_appointments.json
  def create
    @order_item_appointment = OrderItemAppointment.new(order_item_appointment_params)

    respond_to do |format|
      if @order_item_appointment.save
        format.html { redirect_to @order_item_appointment, notice: "Order item appointment was successfully created." }
        format.json { render :show, status: :created, location: @order_item_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order_item_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /order_item_appointments/1 or /order_item_appointments/1.json
  def update
    respond_to do |format|
      if @order_item_appointment.update(order_item_appointment_params)
        format.html { redirect_to @order_item_appointment, notice: "Order item appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @order_item_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order_item_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /order_item_appointments/1 or /order_item_appointments/1.json
  def destroy
    @order_item_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to order_item_appointments_path, notice: "Order item appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_item_appointment
      @order_item_appointment = OrderItemAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_item_appointment_params
      params.expect(order_item_appointment: [ :order_id, :appoint_to_id, :appoint_to_type, :unit_price, :quantity, :total_price, :name, :description, :status, :business_type, :discarded_at ])
    end
end

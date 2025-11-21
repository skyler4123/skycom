class CartAppointmentsController < ApplicationController
  before_action :set_cart_appointment, only: %i[ show edit update destroy ]

  # GET /cart_appointments or /cart_appointments.json
  def index
    @cart_appointments = CartAppointment.all
  end

  # GET /cart_appointments/1 or /cart_appointments/1.json
  def show
  end

  # GET /cart_appointments/new
  def new
    @cart_appointment = CartAppointment.new
  end

  # GET /cart_appointments/1/edit
  def edit
  end

  # POST /cart_appointments or /cart_appointments.json
  def create
    @cart_appointment = CartAppointment.new(cart_appointment_params)

    respond_to do |format|
      if @cart_appointment.save
        format.html { redirect_to @cart_appointment, notice: "Cart appointment was successfully created." }
        format.json { render :show, status: :created, location: @cart_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @cart_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cart_appointments/1 or /cart_appointments/1.json
  def update
    respond_to do |format|
      if @cart_appointment.update(cart_appointment_params)
        format.html { redirect_to @cart_appointment, notice: "Cart appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @cart_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @cart_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cart_appointments/1 or /cart_appointments/1.json
  def destroy
    @cart_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to cart_appointments_path, notice: "Cart appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cart_appointment
      @cart_appointment = CartAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def cart_appointment_params
      params.expect(cart_appointment: [ :cart_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

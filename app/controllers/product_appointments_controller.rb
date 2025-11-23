class ProductAppointmentsController < ApplicationController
  before_action :set_product_appointment, only: %i[ show edit update destroy ]

  # GET /product_appointments or /product_appointments.json
  def index
    @product_appointments = ProductAppointment.all
  end

  # GET /product_appointments/1 or /product_appointments/1.json
  def show
  end

  # GET /product_appointments/new
  def new
    @product_appointment = ProductAppointment.new
  end

  # GET /product_appointments/1/edit
  def edit
  end

  # POST /product_appointments or /product_appointments.json
  def create
    @product_appointment = ProductAppointment.new(product_appointment_params)

    respond_to do |format|
      if @product_appointment.save
        format.html { redirect_to @product_appointment, notice: "Product appointment was successfully created." }
        format.json { render :show, status: :created, location: @product_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_appointments/1 or /product_appointments/1.json
  def update
    respond_to do |format|
      if @product_appointment.update(product_appointment_params)
        format.html { redirect_to @product_appointment, notice: "Product appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_appointments/1 or /product_appointments/1.json
  def destroy
    @product_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to product_appointments_path, notice: "Product appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_appointment
      @product_appointment = ProductAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_appointment_params
      params.expect(product_appointment: [ :product_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

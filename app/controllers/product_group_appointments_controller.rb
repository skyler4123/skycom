class ProductGroupAppointmentsController < ApplicationController
  before_action :set_product_group_appointment, only: %i[ show edit update destroy ]

  # GET /product_group_appointments or /product_group_appointments.json
  def index
    @product_group_appointments = ProductGroupAppointment.all
  end

  # GET /product_group_appointments/1 or /product_group_appointments/1.json
  def show
  end

  # GET /product_group_appointments/new
  def new
    @product_group_appointment = ProductGroupAppointment.new
  end

  # GET /product_group_appointments/1/edit
  def edit
  end

  # POST /product_group_appointments or /product_group_appointments.json
  def create
    @product_group_appointment = ProductGroupAppointment.new(product_group_appointment_params)

    respond_to do |format|
      if @product_group_appointment.save
        format.html { redirect_to @product_group_appointment, notice: "Product group appointment was successfully created." }
        format.json { render :show, status: :created, location: @product_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_group_appointments/1 or /product_group_appointments/1.json
  def update
    respond_to do |format|
      if @product_group_appointment.update(product_group_appointment_params)
        format.html { redirect_to @product_group_appointment, notice: "Product group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_group_appointments/1 or /product_group_appointments/1.json
  def destroy
    @product_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to product_group_appointments_path, notice: "Product group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_group_appointment
      @product_group_appointment = ProductGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_group_appointment_params
      params.expect(product_group_appointment: [ :product_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

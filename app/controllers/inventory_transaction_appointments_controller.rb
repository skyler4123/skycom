class InventoryTransactionAppointmentsController < ApplicationController
  before_action :set_inventory_transaction_appointment, only: %i[ show edit update destroy ]

  # GET /inventory_transaction_appointments or /inventory_transaction_appointments.json
  def index
    @inventory_transaction_appointments = InventoryTransactionAppointment.all
  end

  # GET /inventory_transaction_appointments/1 or /inventory_transaction_appointments/1.json
  def show
  end

  # GET /inventory_transaction_appointments/new
  def new
    @inventory_transaction_appointment = InventoryTransactionAppointment.new
  end

  # GET /inventory_transaction_appointments/1/edit
  def edit
  end

  # POST /inventory_transaction_appointments or /inventory_transaction_appointments.json
  def create
    @inventory_transaction_appointment = InventoryTransactionAppointment.new(inventory_transaction_appointment_params)

    respond_to do |format|
      if @inventory_transaction_appointment.save
        format.html { redirect_to @inventory_transaction_appointment, notice: "Inventory transaction appointment was successfully created." }
        format.json { render :show, status: :created, location: @inventory_transaction_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @inventory_transaction_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory_transaction_appointments/1 or /inventory_transaction_appointments/1.json
  def update
    respond_to do |format|
      if @inventory_transaction_appointment.update(inventory_transaction_appointment_params)
        format.html { redirect_to @inventory_transaction_appointment, notice: "Inventory transaction appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory_transaction_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @inventory_transaction_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory_transaction_appointments/1 or /inventory_transaction_appointments/1.json
  def destroy
    @inventory_transaction_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to inventory_transaction_appointments_path, notice: "Inventory transaction appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_transaction_appointment
      @inventory_transaction_appointment = InventoryTransactionAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def inventory_transaction_appointment_params
      params.expect(inventory_transaction_appointment: [ :inventory_transaction_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

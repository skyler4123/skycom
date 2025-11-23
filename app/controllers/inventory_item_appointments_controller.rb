class InventoryItemAppointmentsController < ApplicationController
  before_action :set_inventory_item_appointment, only: %i[ show edit update destroy ]

  # GET /inventory_item_appointments or /inventory_item_appointments.json
  def index
    @inventory_item_appointments = InventoryItemAppointment.all
  end

  # GET /inventory_item_appointments/1 or /inventory_item_appointments/1.json
  def show
  end

  # GET /inventory_item_appointments/new
  def new
    @inventory_item_appointment = InventoryItemAppointment.new
  end

  # GET /inventory_item_appointments/1/edit
  def edit
  end

  # POST /inventory_item_appointments or /inventory_item_appointments.json
  def create
    @inventory_item_appointment = InventoryItemAppointment.new(inventory_item_appointment_params)

    respond_to do |format|
      if @inventory_item_appointment.save
        format.html { redirect_to @inventory_item_appointment, notice: "Inventory item appointment was successfully created." }
        format.json { render :show, status: :created, location: @inventory_item_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @inventory_item_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory_item_appointments/1 or /inventory_item_appointments/1.json
  def update
    respond_to do |format|
      if @inventory_item_appointment.update(inventory_item_appointment_params)
        format.html { redirect_to @inventory_item_appointment, notice: "Inventory item appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory_item_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @inventory_item_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory_item_appointments/1 or /inventory_item_appointments/1.json
  def destroy
    @inventory_item_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to inventory_item_appointments_path, notice: "Inventory item appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_item_appointment
      @inventory_item_appointment = InventoryItemAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def inventory_item_appointment_params
      params.expect(inventory_item_appointment: [ :inventory_item_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

class DocumentAppointmentsController < ApplicationController
  before_action :set_document_appointment, only: %i[ show edit update destroy ]

  # GET /document_appointments or /document_appointments.json
  def index
    @document_appointments = DocumentAppointment.all
  end

  # GET /document_appointments/1 or /document_appointments/1.json
  def show
  end

  # GET /document_appointments/new
  def new
    @document_appointment = DocumentAppointment.new
  end

  # GET /document_appointments/1/edit
  def edit
  end

  # POST /document_appointments or /document_appointments.json
  def create
    @document_appointment = DocumentAppointment.new(document_appointment_params)

    respond_to do |format|
      if @document_appointment.save
        format.html { redirect_to @document_appointment, notice: "Document appointment was successfully created." }
        format.json { render :show, status: :created, location: @document_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /document_appointments/1 or /document_appointments/1.json
  def update
    respond_to do |format|
      if @document_appointment.update(document_appointment_params)
        format.html { redirect_to @document_appointment, notice: "Document appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @document_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /document_appointments/1 or /document_appointments/1.json
  def destroy
    @document_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to document_appointments_path, notice: "Document appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document_appointment
      @document_appointment = DocumentAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def document_appointment_params
      params.expect(document_appointment: [ :document_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

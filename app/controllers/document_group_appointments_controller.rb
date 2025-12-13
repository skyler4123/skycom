class DocumentGroupAppointmentsController < ApplicationController
  before_action :set_document_group_appointment, only: %i[ show edit update destroy ]

  # GET /document_group_appointments or /document_group_appointments.json
  def index
    @document_group_appointments = DocumentGroupAppointment.all
  end

  # GET /document_group_appointments/1 or /document_group_appointments/1.json
  def show
  end

  # GET /document_group_appointments/new
  def new
    @document_group_appointment = DocumentGroupAppointment.new
  end

  # GET /document_group_appointments/1/edit
  def edit
  end

  # POST /document_group_appointments or /document_group_appointments.json
  def create
    @document_group_appointment = DocumentGroupAppointment.new(document_group_appointment_params)

    respond_to do |format|
      if @document_group_appointment.save
        format.html { redirect_to @document_group_appointment, notice: "Document group appointment was successfully created." }
        format.json { render :show, status: :created, location: @document_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /document_group_appointments/1 or /document_group_appointments/1.json
  def update
    respond_to do |format|
      if @document_group_appointment.update(document_group_appointment_params)
        format.html { redirect_to @document_group_appointment, notice: "Document group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @document_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /document_group_appointments/1 or /document_group_appointments/1.json
  def destroy
    @document_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to document_group_appointments_path, notice: "Document group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document_group_appointment
      @document_group_appointment = DocumentGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def document_group_appointment_params
      params.expect(document_group_appointment: [ :document_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

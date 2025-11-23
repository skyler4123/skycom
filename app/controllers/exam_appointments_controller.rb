class ExamAppointmentsController < ApplicationController
  before_action :set_exam_appointment, only: %i[ show edit update destroy ]

  # GET /exam_appointments or /exam_appointments.json
  def index
    @exam_appointments = ExamAppointment.all
  end

  # GET /exam_appointments/1 or /exam_appointments/1.json
  def show
  end

  # GET /exam_appointments/new
  def new
    @exam_appointment = ExamAppointment.new
  end

  # GET /exam_appointments/1/edit
  def edit
  end

  # POST /exam_appointments or /exam_appointments.json
  def create
    @exam_appointment = ExamAppointment.new(exam_appointment_params)

    respond_to do |format|
      if @exam_appointment.save
        format.html { redirect_to @exam_appointment, notice: "Exam appointment was successfully created." }
        format.json { render :show, status: :created, location: @exam_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @exam_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exam_appointments/1 or /exam_appointments/1.json
  def update
    respond_to do |format|
      if @exam_appointment.update(exam_appointment_params)
        format.html { redirect_to @exam_appointment, notice: "Exam appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @exam_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @exam_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exam_appointments/1 or /exam_appointments/1.json
  def destroy
    @exam_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to exam_appointments_path, notice: "Exam appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exam_appointment
      @exam_appointment = ExamAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def exam_appointment_params
      params.expect(exam_appointment: [ :exam_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

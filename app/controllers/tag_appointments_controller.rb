class TagAppointmentsController < ApplicationController
  before_action :set_tag_appointment, only: %i[ show edit update destroy ]

  # GET /tag_appointments or /tag_appointments.json
  def index
    @tag_appointments = TagAppointment.all
  end

  # GET /tag_appointments/1 or /tag_appointments/1.json
  def show
  end

  # GET /tag_appointments/new
  def new
    @tag_appointment = TagAppointment.new
  end

  # GET /tag_appointments/1/edit
  def edit
  end

  # POST /tag_appointments or /tag_appointments.json
  def create
    @tag_appointment = TagAppointment.new(tag_appointment_params)

    respond_to do |format|
      if @tag_appointment.save
        format.html { redirect_to @tag_appointment, notice: "Tag appointment was successfully created." }
        format.json { render :show, status: :created, location: @tag_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tag_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tag_appointments/1 or /tag_appointments/1.json
  def update
    respond_to do |format|
      if @tag_appointment.update(tag_appointment_params)
        format.html { redirect_to @tag_appointment, notice: "Tag appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tag_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tag_appointments/1 or /tag_appointments/1.json
  def destroy
    @tag_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to tag_appointments_path, notice: "Tag appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag_appointment
      @tag_appointment = TagAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tag_appointment_params
      params.expect(tag_appointment: [ :tag_id, :appoint_to_id, :appoint_to_type, :value, :description ])
    end
end

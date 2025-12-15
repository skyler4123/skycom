class ArticleGroupAppointmentsController < ApplicationController
  before_action :set_article_group_appointment, only: %i[ show edit update destroy ]

  # GET /article_group_appointments or /article_group_appointments.json
  def index
    @article_group_appointments = ArticleGroupAppointment.all
  end

  # GET /article_group_appointments/1 or /article_group_appointments/1.json
  def show
  end

  # GET /article_group_appointments/new
  def new
    @article_group_appointment = ArticleGroupAppointment.new
  end

  # GET /article_group_appointments/1/edit
  def edit
  end

  # POST /article_group_appointments or /article_group_appointments.json
  def create
    @article_group_appointment = ArticleGroupAppointment.new(article_group_appointment_params)

    respond_to do |format|
      if @article_group_appointment.save
        format.html { redirect_to @article_group_appointment, notice: "Article group appointment was successfully created." }
        format.json { render :show, status: :created, location: @article_group_appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /article_group_appointments/1 or /article_group_appointments/1.json
  def update
    respond_to do |format|
      if @article_group_appointment.update(article_group_appointment_params)
        format.html { redirect_to @article_group_appointment, notice: "Article group appointment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @article_group_appointment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article_group_appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /article_group_appointments/1 or /article_group_appointments/1.json
  def destroy
    @article_group_appointment.destroy!

    respond_to do |format|
      format.html { redirect_to article_group_appointments_path, notice: "Article group appointment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article_group_appointment
      @article_group_appointment = ArticleGroupAppointment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def article_group_appointment_params
      params.expect(article_group_appointment: [ :article_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end

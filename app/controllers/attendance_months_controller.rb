class AttendanceMonthsController < ApplicationController
  before_action :set_attendance_month, only: %i[ show edit update destroy ]

  # GET /attendance_months or /attendance_months.json
  def index
    @attendance_months = AttendanceMonth.all
  end

  # GET /attendance_months/1 or /attendance_months/1.json
  def show
  end

  # GET /attendance_months/new
  def new
    @attendance_month = AttendanceMonth.new
  end

  # GET /attendance_months/1/edit
  def edit
  end

  # POST /attendance_months or /attendance_months.json
  def create
    @attendance_month = AttendanceMonth.new(attendance_month_params)

    respond_to do |format|
      if @attendance_month.save
        format.html { redirect_to @attendance_month, notice: "Attendance month was successfully created." }
        format.json { render :show, status: :created, location: @attendance_month }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attendance_month.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attendance_months/1 or /attendance_months/1.json
  def update
    respond_to do |format|
      if @attendance_month.update(attendance_month_params)
        format.html { redirect_to @attendance_month, notice: "Attendance month was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @attendance_month }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @attendance_month.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendance_months/1 or /attendance_months/1.json
  def destroy
    @attendance_month.destroy!

    respond_to do |format|
      format.html { redirect_to attendance_months_path, notice: "Attendance month was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance_month
      @attendance_month = AttendanceMonth.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def attendance_month_params
      params.expect(attendance_month: [ :company_id, :branch_id, :customer_id, :logable_id, :logable_type, :period_id ])
    end
end

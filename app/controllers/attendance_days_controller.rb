class AttendanceDaysController < ApplicationController
  before_action :set_attendance_day, only: %i[ show edit update destroy ]

  # GET /attendance_days or /attendance_days.json
  def index
    @attendance_days = AttendanceDay.all
  end

  # GET /attendance_days/1 or /attendance_days/1.json
  def show
  end

  # GET /attendance_days/new
  def new
    @attendance_day = AttendanceDay.new
  end

  # GET /attendance_days/1/edit
  def edit
  end

  # POST /attendance_days or /attendance_days.json
  def create
    @attendance_day = AttendanceDay.new(attendance_day_params)

    respond_to do |format|
      if @attendance_day.save
        format.html { redirect_to @attendance_day, notice: "Attendance day was successfully created." }
        format.json { render :show, status: :created, location: @attendance_day }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attendance_day.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attendance_days/1 or /attendance_days/1.json
  def update
    respond_to do |format|
      if @attendance_day.update(attendance_day_params)
        format.html { redirect_to @attendance_day, notice: "Attendance day was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @attendance_day }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @attendance_day.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendance_days/1 or /attendance_days/1.json
  def destroy
    @attendance_day.destroy!

    respond_to do |format|
      format.html { redirect_to attendance_days_path, notice: "Attendance day was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance_day
      @attendance_day = AttendanceDay.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def attendance_day_params
      params.expect(attendance_day: [ :company_id, :branch_id, :employee_id, :logable_id, :logable_type, :period_id, :attendance_date, :check_in, :check_out, :break_start, :break_end, :total_seconds_present, :total_seconds_break, :total_seconds_worked, :total_seconds_overtime, :shift_id, :attendance_status, :recorded_method, :ip_address, :device_id, :location_lat, :location_lng, :notes, :approved_by_id, :approved_at, :edited_by_id, :edited_at ])
    end
end

class BookingPeriodsController < ApplicationController
  before_action :set_booking_period, only: %i[ show edit update destroy ]

  # GET /booking_periods or /booking_periods.json
  def index
    @booking_periods = BookingPeriod.all
  end

  # GET /booking_periods/1 or /booking_periods/1.json
  def show
  end

  # GET /booking_periods/new
  def new
    @booking_period = BookingPeriod.new
  end

  # GET /booking_periods/1/edit
  def edit
  end

  # POST /booking_periods or /booking_periods.json
  def create
    @booking_period = BookingPeriod.new(booking_period_params)

    respond_to do |format|
      if @booking_period.save
        format.html { redirect_to @booking_period, notice: "Booking period was successfully created." }
        format.json { render :show, status: :created, location: @booking_period }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @booking_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /booking_periods/1 or /booking_periods/1.json
  def update
    respond_to do |format|
      if @booking_period.update(booking_period_params)
        format.html { redirect_to @booking_period, notice: "Booking period was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @booking_period }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @booking_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /booking_periods/1 or /booking_periods/1.json
  def destroy
    @booking_period.destroy!

    respond_to do |format|
      format.html { redirect_to booking_periods_path, notice: "Booking period was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking_period
      @booking_period = BookingPeriod.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def booking_period_params
      params.expect(booking_period: [ :booking_resource_id, :period_id, :lifecycle_status, :workflow_status, :business_type ])
    end
end

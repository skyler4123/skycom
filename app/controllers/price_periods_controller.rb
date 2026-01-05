class PricePeriodsController < ApplicationController
  before_action :set_price_period, only: %i[ show edit update destroy ]

  # GET /price_periods or /price_periods.json
  def index
    @price_periods = PricePeriod.all
  end

  # GET /price_periods/1 or /price_periods/1.json
  def show
  end

  # GET /price_periods/new
  def new
    @price_period = PricePeriod.new
  end

  # GET /price_periods/1/edit
  def edit
  end

  # POST /price_periods or /price_periods.json
  def create
    @price_period = PricePeriod.new(price_period_params)

    respond_to do |format|
      if @price_period.save
        format.html { redirect_to @price_period, notice: "Price period was successfully created." }
        format.json { render :show, status: :created, location: @price_period }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @price_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /price_periods/1 or /price_periods/1.json
  def update
    respond_to do |format|
      if @price_period.update(price_period_params)
        format.html { redirect_to @price_period, notice: "Price period was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @price_period }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @price_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /price_periods/1 or /price_periods/1.json
  def destroy
    @price_period.destroy!

    respond_to do |format|
      format.html { redirect_to price_periods_path, notice: "Price period was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_price_period
      @price_period = PricePeriod.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def price_period_params
      params.expect(price_period: [ :price_periodable_id, :price_periodable_type, :period_id, :price_id ])
    end
end

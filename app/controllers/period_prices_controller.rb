class PeriodPricesController < ApplicationController
  before_action :set_period_price, only: %i[ show edit update destroy ]

  # GET /period_prices or /period_prices.json
  def index
    @period_prices = PeriodPrice.all
  end

  # GET /period_prices/1 or /period_prices/1.json
  def show
  end

  # GET /period_prices/new
  def new
    @period_price = PeriodPrice.new
  end

  # GET /period_prices/1/edit
  def edit
  end

  # POST /period_prices or /period_prices.json
  def create
    @period_price = PeriodPrice.new(period_price_params)

    respond_to do |format|
      if @period_price.save
        format.html { redirect_to @period_price, notice: "Period price was successfully created." }
        format.json { render :show, status: :created, location: @period_price }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @period_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /period_prices/1 or /period_prices/1.json
  def update
    respond_to do |format|
      if @period_price.update(period_price_params)
        format.html { redirect_to @period_price, notice: "Period price was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @period_price }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @period_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /period_prices/1 or /period_prices/1.json
  def destroy
    @period_price.destroy!

    respond_to do |format|
      format.html { redirect_to period_prices_path, notice: "Period price was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_period_price
      @period_price = PeriodPrice.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def period_price_params
      params.expect(period_price: [ :period_priceable_id, :period_priceable_type, :period_id, :price_id ])
    end
end

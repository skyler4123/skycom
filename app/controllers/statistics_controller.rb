class StatisticsController < ApplicationController
  before_action :set_statistic, only: %i[ show edit update destroy ]

  # GET /statistics or /statistics.json
  def index
    @statistics = Statistic.all
  end

  # GET /statistics/1 or /statistics/1.json
  def show
  end

  # GET /statistics/new
  def new
    @statistic = Statistic.new
  end

  # GET /statistics/1/edit
  def edit
  end

  # POST /statistics or /statistics.json
  def create
    @statistic = Statistic.new(statistic_params)

    respond_to do |format|
      if @statistic.save
        format.html { redirect_to @statistic, notice: "Statistic was successfully created." }
        format.json { render :show, status: :created, location: @statistic }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @statistic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /statistics/1 or /statistics/1.json
  def update
    respond_to do |format|
      if @statistic.update(statistic_params)
        format.html { redirect_to @statistic, notice: "Statistic was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @statistic }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @statistic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /statistics/1 or /statistics/1.json
  def destroy
    @statistic.destroy!

    respond_to do |format|
      format.html { redirect_to statistics_path, notice: "Statistic was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_statistic
      @statistic = Statistic.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def statistic_params
      params.expect(statistic: [ :owner_id, :owner_type, :data, :recorded_at ])
    end
end

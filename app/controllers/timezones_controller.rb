class TimezonesController < ApplicationController
  before_action :set_timezone, only: %i[ show edit update destroy ]

  # GET /timezones or /timezones.json
  def index
    @timezones = Timezone.all
  end

  # GET /timezones/1 or /timezones/1.json
  def show
  end

  # GET /timezones/new
  def new
    @timezone = Timezone.new
  end

  # GET /timezones/1/edit
  def edit
  end

  # POST /timezones or /timezones.json
  def create
    @timezone = Timezone.new(timezone_params)

    respond_to do |format|
      if @timezone.save
        format.html { redirect_to @timezone, notice: "Timezone was successfully created." }
        format.json { render :show, status: :created, location: @timezone }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @timezone.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /timezones/1 or /timezones/1.json
  def update
    respond_to do |format|
      if @timezone.update(timezone_params)
        format.html { redirect_to @timezone, notice: "Timezone was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @timezone }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @timezone.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /timezones/1 or /timezones/1.json
  def destroy
    @timezone.destroy!

    respond_to do |format|
      format.html { redirect_to timezones_path, notice: "Timezone was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_timezone
      @timezone = Timezone.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def timezone_params
      params.expect(timezone: [ :name, :description, :utc_offset ])
    end
end

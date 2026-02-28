class BookingResourcesController < ApplicationController
  before_action :set_booking_resource, only: %i[ show edit update destroy ]

  # GET /booking_resources or /booking_resources.json
  def index
    @booking_resources = BookingResource.all
  end

  # GET /booking_resources/1 or /booking_resources/1.json
  def show
  end

  # GET /booking_resources/new
  def new
    @booking_resource = BookingResource.new
  end

  # GET /booking_resources/1/edit
  def edit
  end

  # POST /booking_resources or /booking_resources.json
  def create
    @booking_resource = BookingResource.new(booking_resource_params)

    respond_to do |format|
      if @booking_resource.save
        format.html { redirect_to @booking_resource, notice: "Booking resource was successfully created." }
        format.json { render :show, status: :created, location: @booking_resource }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @booking_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /booking_resources/1 or /booking_resources/1.json
  def update
    respond_to do |format|
      if @booking_resource.update(booking_resource_params)
        format.html { redirect_to @booking_resource, notice: "Booking resource was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @booking_resource }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @booking_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /booking_resources/1 or /booking_resources/1.json
  def destroy
    @booking_resource.destroy!

    respond_to do |format|
      format.html { redirect_to booking_resources_path, notice: "Booking resource was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking_resource
      @booking_resource = BookingResource.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def booking_resource_params
      params.expect(booking_resource: [ :company_id, :branch_id, :booking_resourceable_id, :booking_resourceable_type, :name, :description, :lifecycle_status, :workflow_status, :business_type, :discarded_at ])
    end
end

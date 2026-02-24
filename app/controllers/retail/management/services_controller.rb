class Retail::Management::ServicesController < Retail::Management::ApplicationController
  before_action :set_service, only: %i[ show edit update destroy ]

  # GET /retail/:retail_id/management/services
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @services = @retail.cached_services
        render json: { services: @services }
      end
    end
  end

  # GET /retail/:retail_id/management/services/new
  def new
    @service = Service.new
  end

  # POST /retail/:retail_id/management/services
  def create
    @service = Service.new(service_params)
    @service.company_group = @retail
    @service.company = @retail.companies.first # Default to first company, can be made configurable

    respond_to do |format|
      if @service.save
        format.html { redirect_to retail_management_services_path(@retail), notice: "Service was successfully created." }
        format.json { render :show, status: :created, location: @service }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /retail/:retail_id/management/services/:id
  def show
  end

  # GET /retail/:retail_id/management/services/:id/edit
  def edit
  end

  # PATCH/PUT /retail/:retail_id/management/services/:id
  def update
    respond_to do |format|
      if @service.update(service_params)
        format.html { redirect_to retail_management_services_path(@retail), notice: "Service was successfully updated." }
        format.json { render :show, status: :ok, location: @service }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /retail/:retail_id/management/services/:id
  def destroy
    @service.destroy!

    respond_to do |format|
      format.html { redirect_to retail_management_services_path(@retail), notice: "Service was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def service_params
    params.require(:service).permit(:name, :description, :code, :duration, :business_type, :start_at, :category_id)
  end
end

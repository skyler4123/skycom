class School::CoursesController < School::ApplicationController
  # before_action :set_service, only: %i[ show edit update destroy ]

  # GET /services or /services.json
  def index
    @schools = Current.companies

    # render html: "", layout: true
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: @schools }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service
      @service = Service.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def service_params
      params.expect(service: [ :company_id, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at ])
    end
end

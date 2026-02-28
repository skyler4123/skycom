class Education::SchoolsController < Education::ApplicationController
  # before_action :set_company, only: %i[ show edit update destroy ]

  # GET /branches or /branches.json
  def index
    @schools = Current.branches

    # render html: "", layout: true
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: @schools }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company
      @company = Branch.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def company_params
      params.expect(branch: [ :user_id, :parent_branch_id, :name, :description, :code, :status, :ownership_type, :business_type, :currency_code, :registration_number, :vat_id, :address_line_1, :city, :postal_code, :country, :email, :phone_number, :website, :employee_count, :fiscal_year_end_month, :discarded_at ])
    end
end

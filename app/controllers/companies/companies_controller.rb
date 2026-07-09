class Companies::CompaniesController < Companies::ApplicationController
  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company: format_company } }
    end
  end

  def update
    if current_company.update(company_params)
      redirect_to company_dashboards_path(current_company), notice: "Company updated successfully."
    else
      redirect_to edit_company_company_path(current_company, current_company),
        alert: current_company.errors.full_messages.to_sentence
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :description, :email, :phone_number, :website, :timezone, :currency_code)
  end

  def format_company
    current_company.as_json(only: [
      :id, :name, :description, :email, :phone_number, :website,
      :timezone, :currency_code, :business_type, :country_code
    ])
  end
end

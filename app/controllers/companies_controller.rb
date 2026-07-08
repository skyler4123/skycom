class CompaniesController < ApplicationController
  def create
    company = current_user.companies.build(company_params)

    if company.save
      current_user.touch
      respond_to do |format|
        format.html { redirect_to company_dashboards_path(company), notice: "Company created successfully!" }
        format.json { render json: { company: company }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: company.errors.full_messages.to_sentence }
        format.json { render json: { errors: company.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :business_type)
  end
end

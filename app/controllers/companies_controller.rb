class CompaniesController < ApplicationController
  def create
    company = current_user.companies.build(company_params)

    if company.save
      render json: { company: company }, status: :created
    else
      render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :business_type)
  end
end

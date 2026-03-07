class Companies::ApplicationController < ApplicationController
  before_action :set_company

  private

  def set_company
    company_id = params[:company_id]
    @company = Company.find(company_id) if company_id.present?
  end

  def current_company
    @company
  end
end

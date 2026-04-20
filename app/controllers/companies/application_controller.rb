class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee

  private

  def set_company
    company_id = params[:company_id]
    @current_company = Company.find(company_id) if company_id.present?
  end

  def current_company
    @current_company
  end

  def set_employee
    @current_employee = current_user.employees.where(company: current_company).first
  end

  def current_employee
    @current_employee
  end
end

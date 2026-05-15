class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee

  # Order reason: Companies::Authorizable need current_employee
  include Companies::Authorizable

  private

  def set_company
    company_id = params[:company_id]
    # @current_company ||= Company.find(company_id) if company_id.present?
    @current_company ||= Company.cached_find(company_id) if company_id.present?
  end

  def current_company
    @current_company
  end

  def set_employee
    # @current_employee ||= current_user.employees.where(company: current_company).first
    @current_employee ||= Employee.cached_where(user: current_user, company: current_company).first
  end

  def current_employee
    @current_employee
  end
end

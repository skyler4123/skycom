class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee
  before_action :block_access!
  before_action :set_past_due_warning

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

  def set_past_due_warning
    return unless current_company&.lifecycle_status_past_due?
    return if current_company.hide_billing_alerts?
    return unless Time.current.day >= 15

    flash.now[:alert] = "Your account is past due. Please settle outstanding invoices to avoid suspension."
  end
end

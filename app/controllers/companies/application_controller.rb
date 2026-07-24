class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee

  # Order reason: Feature gating checks run before Pundit authorization
  include Companies::FeatureGatingConcern

  # Order reason: Companies::Authorizable need current_employee
  include Companies::Authorizable
  include ApplicationController::WebsocketConcern

  before_action :check_accessable
  before_action :set_billing_warning
  before_action :set_websocket_channels

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

  def set_billing_warning
    return unless current_company&.billing_wallet&.has_unpaid_invoices_at?
    return if current_company.billing_wallet&.hide_billing_alerts?
    return if current_company.billing_wallet.has_unpaid_invoices_at > UNPAID_WARNING_THRESHOLD.ago

    flash.now[:alert] = "Your account has outstanding invoices. Please settle them to avoid suspension."
  end
end

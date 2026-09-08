class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee

  # Order reason: Companies::Authorizable need current_employee
  include Companies::Authorizable
  include ApplicationController::WebsocketConcern
  include Companies::CreditDeductionConcern

  before_action :set_websocket_channels

  # Dynamic search/filter services (DynamicSearch::BaseQueryService subclasses) raise
  # Meilisearch::Error when the search backend is down — surface it as a JSON 503,
  # never silent unfiltered results (docs/DYNAMIC_TABLE.md §2.5).
  rescue_from Meilisearch::Error do |e|
    Rails.logger.error("[DynamicSearch] #{e.message}")
    render json: { errors: [ "Search is temporarily unavailable. Please try again." ] },
      status: :service_unavailable
  end

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

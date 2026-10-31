class Companies::ApplicationController < ApplicationController
  before_action :set_company
  before_action :set_employee

  # Order reason: Companies::Authorizable need current_employee
  include Companies::Authorizable
  include ApplicationController::WebsocketConcern
  include Companies::CreditDeductionConcern

  before_action :set_websocket_channels

  # Export guard: only pages listed in EXPORT_ENABLED_RESOURCES may serve an
  # export request (`?export=1`). Centralized so individual controllers need
  # no per-page check. Docs: docs/EXPORT.md
  before_action :ensure_export_enabled, if: -> { params[:export].present? }

  # Dynamic search/filter services (DynamicSearch::BaseQueryService subclasses) raise
  # Meilisearch::Error when the search backend is down — surface it as a JSON 503,
  # never silent unfiltered results (docs/DYNAMIC_TABLE.md §2.5).
  rescue_from Meilisearch::Error do |e|
    Rails.logger.error("[DynamicSearch] #{e.message}")
    render json: { errors: [ "Search is temporarily unavailable. Please try again." ] },
      status: :service_unavailable
  end

  private

  def ensure_export_enabled
    unless EXPORT_ENABLED_RESOURCES.include?(controller_name)
      render json: { errors: [ "Export is not enabled for this page" ] }, status: :unprocessable_content
    end
  end
  def set_company
    company_id = params[:company_id]
    return unless company_id.present?

    cached_company = Rails.sync_cache.fetch(CacheKeyService.company(company_id), expires_in: CACHE_DEFAULT_EXPIRY) do
      c = Company.find_by(id: company_id)
      next nil unless c
      attrs = c.attributes
      c.class.defined_enums.each do |enum_name, mapping|
        value = attrs[enum_name]
        attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
      end
      attrs
    end
    if cached_company.present?
      attrs = cached_company.dup
      Company.defined_enums.each do |enum_name, mapping|
        value = attrs[enum_name]
        attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
      end
      @current_company = Company.instantiate(attrs)
    else
      @current_company = nil
    end
  end

  def current_company
    @current_company
  end

  def set_employee
    return unless current_user && current_company

    cache_key = CacheKeyService.employee_record(user_id: current_user.id, company_id: current_company.id)
    cached_employee = Rails.sync_cache.fetch(cache_key, expires_in: CACHE_DEFAULT_EXPIRY) do
      e = Employee.find_by(user: current_user, company: current_company)
      next nil unless e
      attrs = e.attributes
      e.class.defined_enums.each do |enum_name, mapping|
        value = attrs[enum_name]
        attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
      end
      attrs
    end
    if cached_employee.present?
      attrs = cached_employee.dup
      Employee.defined_enums.each do |enum_name, mapping|
        value = attrs[enum_name]
        attrs[enum_name] = mapping[value] if value.is_a?(String) && mapping.key?(value)
      end
      @current_employee = Employee.instantiate(attrs)
    else
      @current_employee = nil
    end
  end

  def current_employee
    @current_employee
  end
end

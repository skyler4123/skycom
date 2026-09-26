class CalendarSyncJob < ApplicationJob
  queue_as :calendar_sync

  def perform(company_id: nil, payload:)
    integration = resolve_integration(company_id)
    return unless integration

    CalendarAdapters::CalComAdapter.new(integration).process_webhook(payload)
  end

  private

  def resolve_integration(company_id)
    scope = CalendarIntegration.where(provider: "cal_com", status: :active)
    scope = scope.where(company_id: company_id) if company_id.present?
    scope.first
  end
end

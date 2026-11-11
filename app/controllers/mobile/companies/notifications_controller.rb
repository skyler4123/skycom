# frozen_string_literal: true

# Mobile::Companies::NotificationsController — Shell-First notifications list.
# The page shell hydrates from .json; no notification content is server-rendered.
# Serves Stimulus: Mobile_Companies_Notifications_IndexController
# Endpoints: GET /mobile/companies/:company_id/notifications(.json)
# Docs: docs/MOBILE.md §2-§3
class Mobile::Companies::NotificationsController < Mobile::Companies::BaseController
  def index
    respond_to do |format|
      format.html do
        @page_title = "Notifications"
        render_mobile_shell(json_url: mobile_company_notifications_path(@company, format: :json))
      end
      format.json { render json: notifications_payload }
    end
  end

  private

  def notifications_payload
    {
      company: { id: @company.id, name: @company.name },
      employee: { name: @employee.name },
      notifications: Notification.subscribed_for(@employee, @company)
        .order(created_at: :desc)
        .map do |notification|
          {
            id: notification.id,
            name: notification.name,
            description: notification.description,
            severity: notification.severity,
            created_at: notification.created_at
          }
        end
    }
  end
end

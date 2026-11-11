import { Controller } from "@hotwired/stimulus"
import { escapeHtml } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileDate,
  mobileHumanize,
  mobileEmptyState,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile notifications — Shell-First list of the broadcasts subscribed through
// the employee's notification tags.
// Depends on BE: Mobile::Companies::NotificationsController#index
// Endpoints: GET /mobile/companies/:company_id/notifications.json
// Docs: docs/MOBILE.md §2-§3
export default class Mobile_Companies_Notifications_IndexController extends Controller {
  async connect() {
    document.title = "Notifications"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  severityClass(severity) {
    if (severity === "critical") return "bg-danger/10 text-danger"
    if (severity === "warning") return "bg-warning/10 text-warning"
    return "bg-primary/10 text-primary"
  }

  contentHTML({ company, employee, notifications = [] }) {
    const list = notifications.length
      ? notifications.map((notification) => `
          <section class="flex flex-col gap-2 rounded-xl border border-line bg-card p-4 shadow-sm">
            <div class="flex items-center justify-between gap-2">
              <h2 class="truncate text-sm font-bold text-foreground">${escapeHtml(notification.name)}</h2>
              <span class="shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${this.severityClass(notification.severity)}">
                ${escapeHtml(mobileHumanize(notification.severity))}
              </span>
            </div>
            <p class="text-sm text-muted-foreground">${escapeHtml(notification.description)}</p>
            <span class="text-xs text-muted-foreground">${mobileDate(notification.created_at)}</span>
          </section>
        `).join("")
      : mobileEmptyState({ title: "No notifications", hint: "You have no notifications right now." })

    return `
      ${mobileHeader({
        title: "Notifications",
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(
        `<div class="flex flex-col gap-4">${list}</div>`,
        `data-controller="mobile--notifications" data-mobile--notifications-company-id-value="${company.id}"`
      )}
    `
  }
}

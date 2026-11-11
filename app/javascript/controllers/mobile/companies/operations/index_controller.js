import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileHumanize,
  mobileEmptyState,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile operations list — every accessible operation appointment for the
// company, with a launch button for the consoles that have a mobile page.
// Depends on BE: Mobile::Companies::OperationsController#index
// Endpoints: GET /mobile/companies/:company_id/operations.json
// Docs: docs/MOBILE.md §2-§3, docs/OPERATIONS.md
export default class Mobile_Companies_Operations_IndexController extends Controller {
  async connect() {
    document.title = "Operations"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  contentHTML({ company, employee, appointments = [] }) {
    const countLabel = `${appointments.length} ${translate(appointments.length === 1 ? "operation" : "operations")}`
    const body = appointments.length
      ? appointments.map((appointment) => this.appointmentHTML(appointment, company.id)).join("")
      : mobileEmptyState({
          title: "No operations yet",
          hint: "Add a branch or warehouse to start using operations.",
          icon: "apps"
        })

    return `
      ${mobileHeader({
        title: "Operations",
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          <section class="flex items-center justify-between gap-3 rounded-xl border border-line bg-card p-4 shadow-sm">
            <div class="flex min-w-0 items-center gap-3">
              <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <span class="material-symbols-outlined text-xl">apps</span>
              </span>
              <div class="min-w-0">
                <p class="truncate text-sm font-bold text-foreground">${escapeHtml(company.name)}</p>
                <p class="text-xs text-muted-foreground">${translate("Operations for this company")}</p>
              </div>
            </div>
            <span class="shrink-0 rounded-full bg-muted px-2.5 py-0.5 text-xs font-semibold text-muted-foreground">${countLabel}</span>
          </section>
          ${body}
        </div>
      `)}
    `
  }

  appointmentHTML(appointment, companyId) {
    const operation = appointment.operation
    const locationName = appointment.location?.name || "—"
    const subtitle = [ operation.code, appointment.location?.name ].filter(Boolean).join(" • ")

    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-start justify-between gap-2">
          <div class="flex min-w-0 items-center gap-3">
            <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-muted text-muted-foreground">
              <span class="material-symbols-outlined text-xl">storefront</span>
            </span>
            <div class="min-w-0">
              <h2 class="truncate text-sm font-bold text-foreground">${escapeHtml(operation.name || translate("Untitled operation"))}</h2>
              <p class="truncate text-xs text-muted-foreground">${escapeHtml(subtitle)}</p>
            </div>
          </div>
          <div class="flex shrink-0 flex-col items-end gap-1">
            <span class="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
              ${escapeHtml(mobileHumanize(appointment.appointment_workflow_status))}
            </span>
            <span class="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground">
              ${escapeHtml(mobileHumanize(operation.workflow_status))}
            </span>
          </div>
        </div>

        <div class="mt-3 grid grid-cols-2 gap-2">
          <div class="rounded-lg border border-line bg-background p-2.5">
            <p class="text-xs text-muted-foreground">${translate("Type")}</p>
            <p class="mt-0.5 text-sm font-semibold text-foreground">${escapeHtml(operation.operation_type.toUpperCase())}</p>
          </div>
          <div class="rounded-lg border border-line bg-background p-2.5">
            <p class="text-xs text-muted-foreground">${translate("Location")}</p>
            <p class="mt-0.5 text-sm font-semibold text-foreground">${escapeHtml(locationName)}</p>
          </div>
        </div>

        ${this.launchLinkHTML(appointment, companyId)}
      </section>
    `
  }

  launchLinkHTML(appointment, companyId) {
    const operation = appointment.operation
    const locationId = appointment.location?.id
    const linkClass = "mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-lg bg-primary text-sm font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 active:scale-95"

    const branchLinks = {
      pos: {
        path: Helpers.mobile_company_pos_path(companyId, operation.id, { branch_id: locationId }),
        label: "Open POS",
        icon: "point_of_sale"
      },
      booking: {
        path: Helpers.mobile_company_booking_path(companyId, operation.id, { branch_id: locationId }),
        label: "Open Booking",
        icon: "event_available"
      },
      reception: {
        path: Helpers.mobile_company_reception_path(companyId, operation.id, { branch_id: locationId }),
        label: "Open Reception",
        icon: "concierge"
      },
      store_manager: {
        path: Helpers.mobile_company_store_manager_path(companyId, operation.id, { branch_id: locationId }),
        label: "Open Store Manager",
        icon: "storefront"
      }
    }

    if (appointment.location_type === "branch" && branchLinks[operation.operation_type]) {
      const link = branchLinks[operation.operation_type]
      return `<a href="${link.path}" class="${linkClass}">
        <span class="material-symbols-outlined text-xl">${link.icon}</span>
        ${translate(link.label)}
      </a>`
    }

    if (appointment.location_type === "warehouse" && operation.operation_type === "inventory") {
      const path = Helpers.mobile_company_inventory_path(companyId, operation.id, { warehouse_id: locationId })
      return `<a href="${path}" class="${linkClass}">
        <span class="material-symbols-outlined text-xl">inventory_2</span>
        ${translate("Open Inventory")}
      </a>`
    }

    return ""
  }
}

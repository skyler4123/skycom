import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EventConfigs_ShowController extends Companies_LayoutController {
  // Event Config detail — rule toggles for one events category.
  // Depends on BE: Companies::EventConfigsController#show
  // Endpoints: GET <config>.json
  // Docs: docs/EVENTS.md
  /** @type {any | null} */
  config = null

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_event_config_path(companyId, recordId)}.json`)
      this.config = response.event_config

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load event config.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  flagRow(icon, label, value) {
    return `
      <div class="flex items-center gap-3">
        <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
          <span class="material-symbols-outlined">${icon}</span>
        </div>
        <div>
          <p class="text-xs font-medium text-muted-foreground">${label}</p>
          <p class="text-sm font-semibold">${value
            ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-success/10 text-success ">${translate("True")}</span>`
            : `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-background text-foreground ">${translate("False")}</span>`}</p>
        </div>
      </div>
    `
  }

  showHTML() {
    const c = this.config
    if (!c) return `<div class="p-8 text-center">${translate("Event Config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_event_configs_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Event Configs")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-primary/20 /30 bg-primary/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">tune</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${c.category?.name || translate("N/A")}</h2>
              <p class="font-semibold text-primary">${translate("Event Config")}</p>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            ${this.flagRow("inventory", translate("Hold Stock"), c.create_stock_pending)}
            ${this.flagRow("lock", translate("Strict Hold"), c.strict_stock_hold)}
            ${this.flagRow("order_approve", translate("Create Order"), c.create_order_on_complete)}
            ${this.flagRow("meeting_room", translate("Facility Check"), c.warn_on_facility_overlap)}
            ${this.flagRow("badge", translate("Host Check"), c.warn_on_host_overlap)}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_event_config_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Event Config")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

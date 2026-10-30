import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EventConfigs_EditController extends Companies_LayoutController {
  // Edit Event Config page — rule toggles for one events category.
  // Depends on BE: Companies::EventConfigsController#edit (config + categories), #update (HTML redirect)
  // Endpoints: GET <config>.json, PATCH /companies/:id/event_configs/:id (data-turbo=false, novalidate)
  // Docs: docs/EVENTS.md
  /** @type {any | null} */
  config = null

  /** @type {any[]} */
  categories = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_event_config_path(companyId, recordId)}.json`)
      this.config = response.event_config
      this.categories = response.categories || []

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

  toggleField(name, label, checked, hint) {
    return `
      <div class="flex items-center gap-3 py-2">
        <input type="hidden" name="event_config[${name}]" value="false">
        <input type="checkbox" name="event_config[${name}]" value="true" ${checked ? 'checked' : ''}
          class="h-5 w-5 rounded border-line text-primary cursor-pointer">
        <span class="flex items-center gap-1 text-sm text-foreground">${label}
          <span ${tooltip(translate(hint))} class="inline-flex cursor-pointer text-muted-foreground hover:text-muted-foreground ">
            <span class="material-symbols-outlined text-[16px]!">info</span>
          </span>
        </span>
      </div>
    `
  }

  contentHTML() {
    const c = this.config
    if (!c) return `<div class="p-8 text-center">${translate("Event Config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const categoryName = c.category?.name || ""
    const title = categoryName ? `${translate("Edit Event Config")} — ${categoryName}` : translate("Edit Event Config")

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${title}</h2>
        <p class="text-sm text-muted-foreground">${translate("This config applies to all events in this category.")} <span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-primary/10 text-primary ">${categoryName}</span></p>

        <div class="grid grid-cols-2 gap-4">
          ${this.toggleField("create_stock_pending", translate("Hold Stock"), c.create_stock_pending, "ON reserves required stock as event holds on save. OFF creates no hold.")}
          ${this.toggleField("strict_stock_hold", translate("Strict Hold"), c.strict_stock_hold, "ON blocks the save when a hold fails. OFF saves with a warning.")}
          ${this.toggleField("create_order_on_complete", translate("Create Order"), c.create_order_on_complete, "ON builds a pending order when the event completes. OFF builds nothing.")}
          ${this.toggleField("warn_on_facility_overlap", translate("Facility Check"), c.warn_on_facility_overlap, "ON warns on double-booked facilities without blocking. OFF stays silent.")}
          ${this.toggleField("warn_on_host_overlap", translate("Host Check"), c.warn_on_host_overlap, "ON warns on double-booked hosts without blocking. OFF stays silent.")}
        </div>

        <div class="flex justify-end gap-3 pt-6 border-t border-line">
          <a href="${Helpers.company_event_config_path(companyId, c.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Event Config")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.company_event_config_path(companyId, c.id),
            method: "PATCH",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}

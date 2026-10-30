import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EventConfigs_IndexController extends Companies_LayoutController {
  // Event Configs dashboard — one rule row per events category.
  // Depends on BE: Companies::EventConfigsController#index
  // Endpoints: GET <pathname>.json — traditional GET form, full-page submit
  // Docs: docs/EVENTS.md
  static targets = ["configsList"]

  /** @type {any[]} */
  configs = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json${window.location.search}`)
      this.configs = response.event_configs || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load event configs") }${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  flagBadge(value) {
    return value
      ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-success/10 text-success ">${translate("True")}</span>`
      : `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-background text-foreground ">${translate("False")}</span>`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          ${this.renderTableTitle()}

          <div class="flex justify-end mb-6">
            <a href="${Helpers.new_company_event_config_path(currentCompany().id)}"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.configs,
              columns: [
                { key: "category", name: translate("Category") },
                { key: "create_stock_pending", name: translate("Hold Stock") },
                { key: "strict_stock_hold", name: translate("Strict Hold") },
                { key: "create_order_on_complete", name: translate("Create Order") },
                { key: "warn_on_facility_overlap", name: translate("Facility Check") },
                { key: "warn_on_host_overlap", name: translate("Host Check") }
              ],
              identifier: this.identifier,
              target: "configsList",
              mappingLookup: {},
              renderers: {
                category: (value, record) => `<span class="font-medium text-foreground">${record.category?.name || '—'}</span>`,
                create_stock_pending: (value) => this.flagBadge(value),
                strict_stock_hold: (value) => this.flagBadge(value),
                create_order_on_complete: (value) => this.flagBadge(value),
                warn_on_facility_overlap: (value) => this.flagBadge(value),
                warn_on_host_overlap: (value) => this.flagBadge(value)
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_company_event_config_path(currentCompany().id, record.id)}"
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}

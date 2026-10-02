import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EventConfigs_NewController extends Companies_LayoutController {
  // New Event Config page — category + five rule toggles.
  // Depends on BE: Companies::EventConfigsController#new (categories), #create (HTML redirect)
  // Endpoints: GET <pathname>.json, POST /companies/:id/event_configs (data-turbo=false)
  // Docs: docs/EVENTS.md
  /** @type {any[]} */
  categories = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.categories = response.categories || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load event config.") }${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  toggleField(name, label, checked) {
    return `
      <div class="flex items-center gap-3 py-2">
        <input type="hidden" name="event_config[${name}]" value="false">
        <input type="checkbox" name="event_config[${name}]" value="true" ${checked ? 'checked' : ''}
          class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
        <span class="text-sm text-slate-900 dark:text-white">${label}</span>
      </div>
    `
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Event Config")}</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
          <select
            name="event_config[category_id]"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
          >
            ${selectOptionsHTML(cloneNewKey(this.categories, "id", "value"), null)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          ${this.toggleField("create_stock_pending", translate("Hold Stock"), true)}
          ${this.toggleField("strict_stock_hold", translate("Strict Hold"), false)}
          ${this.toggleField("create_order_on_complete", translate("Create Order"), true)}
          ${this.toggleField("warn_on_facility_overlap", translate("Facility Check"), true)}
          ${this.toggleField("warn_on_host_overlap", translate("Host Check"), true)}
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Event Config")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_event_configs_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}

import { Controller } from "@hotwired/stimulus"
import { currentSettings } from "controllers/helpers/auth_helpers"
import { SIDEBAR_ITEMS, SYSTEM_ITEM_KEYS, DEFAULT_SETTINGS_CODE } from "controllers/companies/sidebar_items"

export default class Companies_Settings_Tabs_SidebarController extends Controller {
  /** @type {Setting | null} */
  setting = null

  /** @type {Array<SidebarItem & { icon: string, label: string, group: string }>} */
  items = []

  connect() {
    const settings = currentSettings()
    this.setting = settings.find(s => s.code === DEFAULT_SETTINGS_CODE) || settings[0] || null
    const stored = this.setting?.metadata?.sidebar_items || []

    this.items = SIDEBAR_ITEMS.map(item => {
      const found = stored.find(s => s.key === item.key)
      return { ...item, visible: found ? found.visible !== false : true }
    })

    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    const companyItems = this.items.filter(i => i.group === "company")
    const systemItems = this.items.filter(i => i.group === "system")

    const group = (label, list) => `
      <div class="mb-6">
        <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3 ml-1">${translate(label)}</p>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          ${list.map(i => this.rowHTML(i)).join('')}
        </div>
      </div>
    `

    return `
      <div class="p-6">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h3 class="text-lg font-semibold text-slate-900 dark:text-white">${translate("Sidebar Items")}</h3>
            <p class="text-sm text-slate-500 mt-1">${translate("Choose which navigation items appear in the sidebar")}</p>
          </div>
          <button
            type="button"
            data-action="click->${this.identifier}#save"
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer"
          >
            <span class="material-symbols-outlined text-[18px]">save</span>
            ${translate("Save Changes")}
          </button>
        </div>
        ${group("Company", companyItems)}
        ${group("System", systemItems)}
      </div>
    `
  }

  rowHTML(item) {
    const locked = item.group === "system"
    const checked = item.visible ? 'checked' : ''
    return `
      <label class="flex items-center justify-between gap-3 px-4 py-3 rounded-lg border border-slate-200 dark:border-slate-700 ${locked ? 'bg-slate-50 dark:bg-slate-800/50 cursor-not-allowed' : 'cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50'}">
        <span class="flex items-center gap-3 min-w-0">
          <span class="material-symbols-outlined text-slate-500 dark:text-slate-400 shrink-0">${item.icon}</span>
          <span class="flex-1 text-sm font-medium text-slate-900 dark:text-white truncate">${translate(item.label)}</span>
          ${locked ? `<span class="shrink-0 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">${translate("System")}</span>` : ''}
        </span>
        <input type="checkbox" data-key="${item.key}" ${checked} ${locked ? 'disabled' : ''} class="h-4 w-4 rounded border-slate-300 text-blue-600 shrink-0 ${locked ? 'opacity-50' : 'cursor-pointer'}" />
      </label>
    `
  }

  async save() {
    if (!this.setting) {
      toast({ type: "error", message: translate("No settings configured for this company") })
      return
    }

    const sidebar_items = Array.from(this.element.querySelectorAll('input[type="checkbox"][data-key]'))
      .filter(cb => !SYSTEM_ITEM_KEYS.has(cb.dataset.key))
      .map(cb => ({ key: cb.dataset.key, visible: cb.checked }))

    try {
      const response = await fetchJson(Helpers.company_settings_path(currentCompany().id, this.setting.id), {
        method: "PATCH",
        body: { setting: { sidebar_items } }
      })
      clearClientCacheAndReload({ type: "success", message: response.message || translate("Settings updated") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update settings") })
    }
  }
}
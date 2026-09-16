import { Controller } from "@hotwired/stimulus"
import { currentSettings } from "controllers/helpers/auth_helpers"
import {
  SIDEBAR_GROUPS,
  SIDEBAR_ITEMS,
  SYSTEM_GROUP_KEYS,
  SYSTEM_ITEM_KEYS,
  DEFAULT_SETTINGS_CODE
} from "controllers/companies/sidebar_items"

export default class Companies_Settings_Tabs_SidebarController extends Controller {
  /** @type {Setting | null} */
  setting = null

  /** @type {Array<SidebarGroup & { visible: boolean }>} */
  groups = []

  /** @type {Array<SidebarItem & { icon: string, label: string, group: string, visible: boolean }>} */
  items = []

  connect() {
    const settings = currentSettings()
    this.setting = settings.find(s => s.code === DEFAULT_SETTINGS_CODE) || settings[0] || null

    const storedGroups = this.setting?.metadata?.sidebar_groups || []
    this.groups = SIDEBAR_GROUPS.map(group => {
      const found = storedGroups.find(g => g.key === group.key)
      return { ...group, visible: found ? found.visible !== false : true }
    })

    const storedItems = this.setting?.metadata?.sidebar_items || []
    this.items = SIDEBAR_ITEMS.map(item => {
      const found = storedItems.find(s => s.key === item.key)
      return { ...item, visible: found ? found.visible !== false : true }
    })

    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    return `
      <div class="p-6">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div>
            <h3 class="text-lg font-semibold text-slate-900 dark:text-white">${translate("Sidebar Items")}</h3>
            <p class="text-sm text-slate-500 mt-1">${translate("Choose which navigation groups and items appear in the sidebar")}</p>
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
        ${this.groups.map(group => this.groupHTML(group)).join('')}
      </div>
    `
  }

  groupHTML(groupConfig) {
    const locked = SYSTEM_GROUP_KEYS.has(groupConfig.key)
    const checked = groupConfig.visible ? 'checked' : ''
    const items = this.items.filter(i => i.group === groupConfig.key)

    return `
      <div class="mb-4 rounded-xl border border-slate-200 dark:border-slate-700" data-sidebar-section="${groupConfig.key}">
        <label class="flex items-center justify-between gap-3 px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700 rounded-t-xl ${locked ? 'cursor-not-allowed' : 'cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800'}"
          ${groupConfig.comingSoon ? tooltip({ html: translate("Coming soon"), position: "right" }) : ""}>
          <span class="flex items-center gap-1 min-w-0">
            <span class="flex-1 text-sm font-bold text-slate-900 dark:text-white truncate">${translate(groupConfig.label)}</span>
            ${groupConfig.comingSoon ? `<span class="material-symbols-outlined text-[14px] text-amber-500 dark:text-amber-400 shrink-0">error</span>` : ''}
            ${locked ? `<span class="shrink-0 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">${translate("System")}</span>` : ''}
          </span>
          <input type="checkbox" data-group-key="${groupConfig.key}" ${checked} ${locked ? 'disabled' : ''}
            data-action="change->${this.identifier}#toggleGroup"
            class="h-4 w-4 rounded border-slate-300 text-blue-600 shrink-0 ${locked ? 'opacity-50' : 'cursor-pointer'}" />
        </label>
        ${items.length > 0 ? `
          <div class="p-3 grid grid-cols-1 md:grid-cols-2 gap-3" data-sidebar-items>
            ${items.map(item => this.rowHTML(item)).join('')}
          </div>
        ` : ""}
      </div>
    `
  }

  rowHTML(item) {
    const locked = SYSTEM_ITEM_KEYS.has(item.key)
    const disabled = locked || this.groupDisabled(item.group)
    const checked = item.visible ? 'checked' : ''
    return `
      <label class="flex items-center justify-between gap-3 px-4 py-3 rounded-lg border border-slate-200 dark:border-slate-700 ${disabled ? 'bg-slate-50 dark:bg-slate-800/50 cursor-not-allowed' : 'cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50'}">
        <span class="flex items-center gap-3 min-w-0">
          <span class="material-symbols-outlined text-slate-500 dark:text-slate-400 shrink-0">${item.icon}</span>
          <span class="flex-1 text-sm font-medium text-slate-900 dark:text-white truncate">${translate(item.label)}</span>
          ${locked ? `<span class="shrink-0 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">${translate("System")}</span>` : ''}
        </span>
        <input type="checkbox" data-key="${item.key}" ${checked} ${disabled ? 'disabled' : ''} class="h-4 w-4 rounded border-slate-300 text-blue-600 shrink-0 ${disabled ? 'opacity-50' : 'cursor-pointer'}" />
      </label>
    `
  }

  groupDisabled(groupKey) {
    const group = this.groups.find(g => g.key === groupKey)
    return group ? !group.visible : false
  }

  toggleGroup(event) {
    const groupKey = event.target.dataset.groupKey
    const section = this.element.querySelector(`[data-sidebar-section="${groupKey}"]`)
    if (!section) return

    const itemsGrid = section.querySelector('[data-sidebar-items]')
    itemsGrid.classList.toggle('opacity-50', !event.target.checked)
    itemsGrid.querySelectorAll('input[type="checkbox"][data-key]').forEach(cb => {
      cb.disabled = !event.target.checked
    })
  }

  async save() {
    if (!this.setting) {
      toast({ type: "error", message: translate("No settings configured for this company") })
      return
    }

    const sidebar_groups = Array.from(this.element.querySelectorAll('input[type="checkbox"][data-group-key]'))
      .filter(cb => !SYSTEM_GROUP_KEYS.has(cb.dataset.groupKey))
      .map(cb => ({ key: cb.dataset.groupKey, visible: cb.checked }))

    const sidebar_items = Array.from(this.element.querySelectorAll('input[type="checkbox"][data-key]'))
      .filter(cb => !SYSTEM_ITEM_KEYS.has(cb.dataset.key))
      .map(cb => ({ key: cb.dataset.key, visible: cb.checked }))

    try {
      const response = await fetchJson(Helpers.company_settings_path(currentCompany().id, this.setting.id), {
        method: "PATCH",
        body: { setting: { sidebar_groups, sidebar_items } }
      })
      clearClientCacheAndReload({ type: "success", message: response.message || translate("Settings updated") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update settings") })
    }
  }
}

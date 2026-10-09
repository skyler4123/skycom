// Settings page — Dynamic Sidebar editor (company-setting level).
//
// Depends on BE: Companies::SettingsController#index (GET list, find the
// DYNAMIC_SIDEBAR record) + #update (PATCH sidebar_groups metadata).
// Custom groups render above the built-in sidebar via
// companies/sidebars/show_controller.js (see docs/SIDEBAR.md).
import Companies_LayoutController from "controllers/companies/layout_controller"
import { DYNAMIC_SIDEBAR_CODE } from "controllers/companies/sidebar_custom"

export default class Companies_Settings_IndexController extends Companies_LayoutController {
  /** @type {string | null} */
  settingId = null

  /** @type {Array<{key: string, name: string, items: Array<{key: string, name: string, url: string}>}>} */
  groups = []

  /** @type {boolean} */
  loaded = false

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      const record = (response.settings || []).find((s) => s.code === DYNAMIC_SIDEBAR_CODE) || null
      if (record) {
        this.settingId = record.id
        const raw = record.metadata?.sidebar_groups || record.sidebar_groups || []
        this.groups = Array.isArray(raw) ? raw.map((g) => ({
          key: String(g.key || `group-${Math.random().toString(36).slice(2, 8)}`),
          name: String(g.name || ""),
          items: Array.isArray(g.items) ? g.items.map((item) => ({
            key: String(item.key || `item-${Math.random().toString(36).slice(2, 8)}`),
            name: String(item.name || ""),
            url: String(item.url || "")
          })) : []
        })) : []
      }
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load settings") })
    }

    this.loaded = true
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  companyId() {
    return currentCompany()?.id || window.location.pathname.split("/")[2]
  }

  updateUrl() {
    return Helpers.company_settings_path(this.companyId(), this.settingId)
  }

  newKey(prefix) {
    return `${prefix}-${Date.now().toString(36)}${Math.floor(Math.random() * 1e4).toString(36)}`
  }

  addGroup() {
    this.groups.push({ key: this.newKey("group"), name: "", items: [] })
    this.renderContent()
  }

  removeGroup(event) {
    const { groupKey } = event.params
    this.groups = this.groups.filter((g) => g.key !== groupKey)
    this.renderContent()
  }

  addItem(event) {
    const { groupKey } = event.params
    const group = this.groups.find((g) => g.key === groupKey)
    if (group) {
      group.items.push({ key: this.newKey("item"), name: "", url: "" })
      this.renderContent()
    }
  }

  removeItem(event) {
    const { groupKey, itemKey } = event.params
    const group = this.groups.find((g) => g.key === groupKey)
    if (group) {
      group.items = group.items.filter((i) => i.key !== itemKey)
      this.renderContent()
    }
  }

  // Keep state in sync while typing (structural re-renders would drop focus).
  syncField(event) {
    const { groupKey, itemKey, field } = event.params
    const group = this.groups.find((g) => g.key === groupKey)
    if (!group) return
    if (itemKey) {
      const item = group.items.find((i) => i.key === itemKey)
      if (item && (field === "name" || field === "url")) item[field] = event.target.value
    } else if (field === "name") {
      group.name = event.target.value
    }
  }

  async save(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(this.updateUrl(), {
        method: "PATCH",
        body: new FormData(event.target)
      })
      clearClientCacheAndReload({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update dynamic sidebar") })
    }
  }

  groupFieldsHTML(group, gi) {
    const itemsHTML = group.items.map((item, ii) => `
      <div class="flex flex-col sm:flex-row gap-2">
        <label class="flex-1 space-y-1">
          <span class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Item name")}</span>
          <input
            type="text"
            name="setting[metadata][sidebar_groups][${gi}][items][${ii}][name]"
            value="${escapeHtml(item.name)}"
            placeholder="${translate("Item name")}"
            data-action="input->${this.identifier}#syncField"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
            data-${this.identifier}-field-param="name"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"
          >
        </label>
        <label class="flex-[2] space-y-1">
          <span class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Item URL")}</span>
          <input
            type="text"
            name="setting[metadata][sidebar_groups][${gi}][items][${ii}][url]"
            value="${escapeHtml(item.url)}"
            placeholder="/companies/:id/orders?workflow_status=pending"
            data-action="input->${this.identifier}#syncField"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
            data-${this.identifier}-field-param="url"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono"
          >
        </label>
        <input type="hidden" name="setting[metadata][sidebar_groups][${gi}][items][${ii}][key]" value="${escapeHtml(item.key)}">
        <button
          type="button"
          data-action="click->${this.identifier}#removeItem"
          data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
          data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
          title="${translate("Delete item")}"
          class="mt-auto p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg cursor-pointer"
        >
          <span class="material-symbols-outlined text-[20px]">delete</span>
        </button>
      </div>
    `).join("")

    return `
      <div class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl space-y-4">
        <div class="flex items-center gap-2">
          <label class="flex-1 space-y-1">
            <span class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Group name")}</span>
            <input
              type="text"
              name="setting[metadata][sidebar_groups][${gi}][name]"
              value="${escapeHtml(group.name)}"
              placeholder="${translate("Group name")}"
              data-action="input->${this.identifier}#syncField"
              data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
              data-${this.identifier}-field-param="name"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-medium"
            >
          </label>
          <input type="hidden" name="setting[metadata][sidebar_groups][${gi}][key]" value="${escapeHtml(group.key)}">
          <button
            type="button"
            data-action="click->${this.identifier}#removeGroup"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            title="${translate("Delete group")}"
            class="mt-auto p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg cursor-pointer"
          >
            <span class="material-symbols-outlined text-[20px]">delete</span>
          </button>
        </div>
        <div class="space-y-3 pl-1">${itemsHTML}</div>
        <button
          type="button"
          data-action="click->${this.identifier}#addItem"
          data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
          class="inline-flex items-center gap-1 px-3 py-1.5 text-sm text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg cursor-pointer"
        >
          <span class="material-symbols-outlined text-[18px]">add</span>
          ${translate("Add Sidebar Item")}
        </button>
      </div>
    `
  }

  contentHTML() {
    if (!this.loaded) {
      return `<div class="p-8 text-center text-sm text-slate-500">...</div>`
    }

    if (!this.settingId) {
      return `
        <div class="p-4 overflow-y-auto">
          <div class="p-10 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 text-center">
            <span class="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600">settings</span>
            <h2 class="mt-3 text-lg font-bold text-slate-900 dark:text-white">${translate("Settings")}</h2>
            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">${translate("Dynamic sidebar is not configured for this company yet.")}</p>
          </div>
        </div>
      `
    }

    const fields = `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Dynamic Sidebar")}</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">${translate("Custom groups appear above the built-in sidebar")}</p>
        </div>
        ${this.groups.length > 0 ? this.groups.map((g, gi) => this.groupFieldsHTML(g, gi)).join("") : `<p class="text-sm text-slate-400 dark:text-slate-500">${translate("No custom groups yet")}</p>`}
        <div class="flex items-center justify-between pt-2">
          <button
            type="button"
            data-action="click->${this.identifier}#addGroup"
            class="inline-flex items-center gap-2 px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg font-medium text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer"
          >
            <span class="material-symbols-outlined text-[20px]">add</span>
            ${translate("Add Group")}
          </button>
          <button
            type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer"
          >
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: this.updateUrl(),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-action="submit->${this.identifier}#save"`,
          html: fields
        })}
      </div>
    `
  }
}

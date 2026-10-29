// Settings page — CompanySetting sidebar editor (company level only).
//
// Depends on BE: Companies::CompanySettingsController#index (GET list, find the
// active sidebar_groups record) + #update (PATCH sidebar_groups metadata).
// Custom groups render above the built-in sidebar via
// companies/sidebars/show_controller.js (see docs/SIDEBAR.md).
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_CompanySettings_IndexController extends Companies_LayoutController {
  /** @type {string | null} */
  settingId = null

  /** @type {Array<{key: string, name: string, items: Array<{key: string, name: string, url: string}>}>} */
  groups = []

  /** @type {boolean} */
  loaded = false

  normalizeGroups(raw) {
    if (!Array.isArray(raw)) return []
    return raw.map((g) => ({
      key: String(g.key || `group-${Math.random().toString(36).slice(2, 8)}`),
      name: String(g.name || ""),
      items: Array.isArray(g.items) ? g.items.map((item) => ({
        key: String(item.key || `item-${Math.random().toString(36).slice(2, 8)}`),
        name: String(item.name || ""),
        url: String(item.url || "")
      })) : []
    }))
  }

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      const list = response.company_settings || response.settings || []
      const record = list.find((s) => s.business_type === "sidebar_groups" && (s.workflow_status === "active" || s.workflow_status === 1))
        || list.find((s) => s.business_type === "sidebar_groups" || s.business_type === 0) || null
      if (record) {
        this.settingId = record.id
        const raw = record.metadata?.sidebar_groups || record.sidebar_groups || []
        this.groups = this.normalizeGroups(raw)
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
    this.groups = [...this.groups, { key: this.newKey("group"), name: "", items: [] }]
    this.renderContent()
  }

  removeGroup(event) {
    const { groupKey } = event.params
    this.groups = this.groups.filter((g) => g.key !== groupKey)
    this.renderContent()
  }

  addItem(event) {
    const { groupKey } = event.params
    this.groups = this.groups.map((g) => {
      if (g.key !== groupKey) return g
      return { ...g, items: [...g.items, { key: this.newKey("item"), name: "", url: "" }] }
    })
    this.renderContent()
  }

  removeItem(event) {
    const { groupKey, itemKey } = event.params
    this.groups = this.groups.map((g) => {
      if (g.key !== groupKey) return g
      return { ...g, items: g.items.filter((i) => i.key !== itemKey) }
    })
    this.renderContent()
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
          <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Item name")}</span>
          <input
            type="text"
            name="company_setting[metadata][sidebar_groups][${gi}][items][${ii}][name]"
            value="${escapeHtml(item.name)}"
            placeholder="${translate("Item name")}"
            data-action="input->${this.identifier}#syncField"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
            data-${this.identifier}-field-param="name"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm"
          >
        </label>
        <label class="flex-[2] space-y-1">
          <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Item URL")}</span>
          <input
            type="text"
            name="company_setting[metadata][sidebar_groups][${gi}][items][${ii}][url]"
            value="${escapeHtml(item.url)}"
            placeholder="/companies/:id/orders?workflow_status=pending"
            data-action="input->${this.identifier}#syncField"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
            data-${this.identifier}-field-param="url"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm font-mono"
          >
        </label>
        <input type="hidden" name="company_setting[metadata][sidebar_groups][${gi}][items][${ii}][key]" value="${escapeHtml(item.key)}">
        <button
          type="button"
          data-action="click->${this.identifier}#removeItem"
          data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
          data-${this.identifier}-item-key-param="${escapeHtml(item.key)}"
          title="${translate("Delete item")}"
          class="mt-auto p-2 text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg cursor-pointer"
        >
          <span class="material-symbols-outlined text-[20px]">delete</span>
        </button>
      </div>
    `).join("")

    return `
      <div class="p-4 border border-line rounded-xl space-y-4">
        <div class="flex items-center gap-2">
          <label class="flex-1 space-y-1">
            <span class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Group name")}</span>
            <input
              type="text"
              name="company_setting[metadata][sidebar_groups][${gi}][name]"
              value="${escapeHtml(group.name)}"
              placeholder="${translate("Group name")}"
              data-action="input->${this.identifier}#syncField"
              data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
              data-${this.identifier}-field-param="name"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm font-medium"
            >
          </label>
          <input type="hidden" name="company_setting[metadata][sidebar_groups][${gi}][key]" value="${escapeHtml(group.key)}">
          <button
            type="button"
            data-action="click->${this.identifier}#removeGroup"
            data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
            title="${translate("Delete group")}"
            class="mt-auto p-2 text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg cursor-pointer"
          >
            <span class="material-symbols-outlined text-[20px]">delete</span>
          </button>
        </div>
        <div class="space-y-3 pl-1">${itemsHTML}</div>
        <button
          type="button"
          data-action="click->${this.identifier}#addItem"
          data-${this.identifier}-group-key-param="${escapeHtml(group.key)}"
          class="inline-flex items-center gap-1 px-3 py-1.5 text-sm text-primary hover:bg-primary/10 rounded-lg cursor-pointer"
        >
          <span class="material-symbols-outlined text-[18px]">add</span>
          ${translate("Add Sidebar Item")}
        </button>
      </div>
    `
  }

  contentHTML() {
    if (!this.loaded) {
      return `<div class="p-8 text-center text-sm text-muted-foreground">...</div>`
    }

    const companyForm = !this.settingId ? `
        <div class="p-10 bg-card rounded-xl border border-line text-center">
          <span class="material-symbols-outlined text-4xl text-muted-foreground/60">settings</span>
          <h2 class="mt-3 text-lg font-bold text-foreground">${translate("Settings")}</h2>
          <p class="mt-1 text-sm text-muted-foreground">${translate("Dynamic sidebar is not configured for this company yet.")}</p>
        </div>
      ` : (() => {
      const fields = `
        <div class="space-y-6">
          <div>
            <h2 class="text-xl font-bold text-foreground">${translate("Company Quick Links")}</h2>
            <p class="mt-1 text-sm text-muted-foreground">${translate("Shared with everyone in this company")}</p>
          </div>
          ${this.groups.length > 0 ? this.groups.map((g, gi) => this.groupFieldsHTML(g, gi)).join("") : `<p class="text-sm text-muted-foreground">${translate("No custom groups yet")}</p>`}
          <div class="flex items-center justify-between pt-2">
            <button
              type="button"
              data-action="click->${this.identifier}#addGroup"
              class="inline-flex items-center gap-2 px-4 py-2 border border-line rounded-lg font-medium text-sm text-foreground hover:bg-muted cursor-pointer"
            >
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add Group")}
            </button>
            <button
              type="submit"
              class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer"
            >
              ${translate("Save Changes")}
            </button>
          </div>
        </div>
      `

      return form({
        action: this.updateUrl(),
        method: "PATCH",
        attributes: `class="p-6 bg-card rounded-xl border border-line" data-action="submit->${this.identifier}#save"`,
        html: fields
      })
    })()

    return `
      <div class="p-4 overflow-y-auto space-y-4">
        ${companyForm}
      </div>
    `
  }
}

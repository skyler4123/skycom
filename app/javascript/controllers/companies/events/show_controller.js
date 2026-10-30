import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Events_ShowController extends Companies_LayoutController {
  // Event detail — core fields + time window + link sections + warnings banner.
  // Depends on BE: Companies::EventsController#show (event + warnings)
  // Endpoints: GET <event>.json
  // Docs: docs/EVENTS.md
  /** @type {Event | null} */
  event = null

  /** @type {string[]} */
  warnings = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_event_path(companyId, recordId)}.json`)
      this.event = response.event
      this.warnings = response.warnings || []

      if (this.event?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.event.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load event.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-muted-foreground/60">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-success/10 text-success ' : 'bg-background text-foreground '}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-foreground">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-foreground">${value}</span>`
    }
  }

  linkListHTML(title, icon, items, nameKey = "name") {
    if (!items || items.length === 0) return ''
    return `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate(title)}</h3>
        <div class="flex flex-wrap gap-2">
          ${items.map(item => `
            <span class="inline-flex items-center gap-1 px-3 py-1 text-sm rounded-lg bg-muted text-foreground">
              <span class="material-symbols-outlined text-[16px]">${icon}</span>
              ${item[nameKey] || item.id}${item.quantity ? ` × ${item.quantity}` : ''}
            </span>
          `).join('')}
        </div>
      </div>
    `
  }

  showHTML() {
    const e = this.event
    if (!e) return `<div class="p-8 text-center">${translate("Event not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === e.category_id)

    const warningsHTML = this.warnings.length > 0 ? `
      <div class="mb-6 p-4 rounded-xl border border-warning/20 bg-warning/10 ">
        <p class="text-sm font-bold text-warning mb-2">${translate("Warnings")}</p>
        <ul class="list-disc list-inside text-sm text-warning space-y-1">
          ${this.warnings.map(w => `<li>${w}</li>`).join('')}
        </ul>
      </div>
    ` : ''

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${field.name}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(e[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_events_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Events")}
          </a>

          ${warningsHTML}

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-primary/20 /30 bg-primary/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">event</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${e.name}</h2>
              <p class="font-semibold text-primary">${e.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-primary/10 /40 px-3 py-1 text-xs font-bold text-primary uppercase">${e.code || translate("N/A")}</span>
                ${Helpers.statusBadge(e.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">schedule</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Start At")}</p>
                <p class="text-sm font-semibold text-foreground">${e.start_at ? new Date(e.start_at).toLocaleString() : translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">schedule</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("End At")}</p>
                <p class="text-sm font-semibold text-foreground">${e.end_at ? new Date(e.end_at).toLocaleString() : translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${category?.name || e.category?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Type")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(e.business_type?.replace('_', ' ') || 'appointment')}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}
          ${this.linkListHTML("Customers", "person", e.customers)}
          ${this.linkListHTML("Employees", "badge", e.employees)}
          ${this.linkListHTML("Services", "concierge", e.services)}
          ${this.linkListHTML("Facilities", "meeting_room", e.facilities)}
          ${this.linkListHTML("Stocks", "inventory", e.stocks)}
          ${this.linkListHTML("Orders", "order_approve", e.orders)}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.company_calendar_path(companyId)}"
              class="inline-flex items-center px-6 py-2 border border-line text-foreground rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Calendar")}
            </a>
            <a href="${Helpers.edit_company_event_path(companyId, e.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Event")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

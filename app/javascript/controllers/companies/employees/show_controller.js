import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Employees_ShowController extends Companies_LayoutController {
  /** @type {(Employee & { departments: Department[], roles: Role[], branch: Branch, user: { id: string, email: string }}) | null} */
  employee = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_employee_path(companyId, recordId)}.json`)
      this.employee = response.employee

      if (this.employee?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.employee.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load employee.")}</div>`
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

  showHTML() {
    const e = this.employee
    if (!e) return `<div class="p-8 text-center">${translate("Employee not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === e.category_id)

    const rolesHTML = (e.roles || []).map(r =>
      `<span class="px-2 py-0.5 bg-muted text-muted-foreground text-[10px] font-bold rounded border border-line">${r.name}</span>`
    ).join('')

    const departmentsHTML = (e.departments || []).map(d =>
      `<span class="px-2 py-0.5 bg-primary/10 text-primary text-[10px] font-bold rounded border border-primary/20 ">${d.name}</span>`
    ).join('')

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
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
          <a href="${Helpers.company_employees_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Employees")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-line bg-muted shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-muted-foreground">person</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${e.name}</h2>
              <p class="font-semibold text-muted-foreground">${e.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-foreground uppercase">${e.code || translate("N/A")}</span>
                <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-bold ${e.business_type === 'full_time' ? 'bg-success/10 text-success ' : 'bg-primary/10 text-primary /50 '}">${Helpers.capitalize(e.business_type?.replace('_', ' ') || '')}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">mail</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Email")}</p>
                <p class="text-sm font-semibold text-foreground">${e.user?.email || e.email || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(e.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">business</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Branch")}</p>
                <p class="text-sm font-semibold text-foreground">${e.branch?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${category?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">diversity_3</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Departments")}</p>
                <div class="flex flex-wrap gap-1 mt-1">${departmentsHTML || `<span class="text-xs text-muted-foreground">${translate("N/A")}</span>`}</div>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                <span class="material-symbols-outlined">badge</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Roles")}</p>
                <div class="flex flex-wrap gap-1 mt-1">${rolesHTML || `<span class="text-xs text-muted-foreground">${translate("N/A")}</span>`}</div>
              </div>
            </div>

          </div>

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_employee_path(companyId, e.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Employee")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

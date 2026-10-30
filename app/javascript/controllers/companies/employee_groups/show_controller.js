import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EmployeeGroups_ShowController extends Companies_LayoutController {
  // Employee Group detail — group fields, manager, member links and dynamic
  // property values.
  // Depends on BE: Companies::EmployeeGroupsController#show
  // Endpoints: GET company_employee_group_path.json
  // Docs: docs/HR.md, docs/DYNAMIC_TABLE.md
  /** @type {(EmployeeGroup & { manager: Employee | null, branch: Branch | null, category: Category | null, employees: Employee[] }) | null} */
  employeeGroup = null

  /** @type {Array<{key: string, name: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]
    const recordId = window.location.pathname.split("/").pop()

    try {
      const response = await fetchJson(`${Helpers.company_employee_group_path(companyId, recordId)}.json`)
      this.employeeGroup = response.employee_group

      if (this.employeeGroup?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.employeeGroup.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load employee group.")}</div>`
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
      case "boolean":
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? "bg-success/10 text-success" : "bg-background text-foreground"}">${value ? translate("True") : translate("False")}</span>`
      case "integer":
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case "decimal":
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case "datetime": {
        const date = new Date(value)
        return `<span class="text-sm text-foreground">${date.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-foreground">${escapeHtml(value)}</span>`
    }
  }

  showHTML() {
    const group = this.employeeGroup
    if (!group) return `<div class="p-8 text-center">${translate("Employee Group not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const manager = group.manager
    const employees = group.employees || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined text-[20px]">${field.type === "boolean" ? "check_circle" : field.type === "datetime" ? "calendar_month" : "text_fields"}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${escapeHtml(field.name)}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(group[field.key], field.type)}</p>
              </div>
            </div>
          `).join("")}
        </div>
      </div>
    ` : ""

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_employee_groups_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Employee Groups")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-primary/20 bg-primary/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">group_work</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${escapeHtml(group.name)}</h2>
              <p class="font-semibold text-primary">${escapeHtml(group.description) || ""}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-primary/10 px-3 py-1 text-xs font-bold text-primary uppercase">${escapeHtml(group.code) || translate("N/A")}</span>
                ${group.category?.name ? `<span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-muted-foreground">${escapeHtml(group.category.name)}</span>` : ""}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">apartment</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Branch")}</p>
                <p class="text-sm font-semibold text-foreground">${escapeHtml(group.branch?.name) || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">mail</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Email")}</p>
                <p class="text-sm font-semibold text-foreground">${escapeHtml(group.email) || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${escapeHtml(group.category?.name) || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">badge</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Manager")}</p>
                ${manager
                  ? `<a href="${Helpers.company_employee_path(companyId, manager.id)}" class="text-sm font-semibold text-foreground hover:text-primary transition-colors cursor-pointer">${escapeHtml(manager.name)}</a>`
                  : `<p class="text-sm font-semibold text-muted-foreground">${translate("No manager")}</p>`}
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="border-t border-line pt-6 mt-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider">${translate("Members")}</h3>
              <span class="inline-flex items-center rounded-full bg-primary/10 px-2.5 py-1 text-xs font-bold text-primary">${employees.length}</span>
            </div>

            ${employees.length > 0 ? `
              <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
                ${employees.map(employee => `
                  <a href="${Helpers.company_employee_path(companyId, employee.id)}"
                    class="flex items-center gap-3 rounded-lg border border-line bg-background px-3 py-2 hover:border-primary/40 hover:bg-primary/5 transition-colors cursor-pointer">
                    <div class="flex size-9 items-center justify-center rounded-full bg-primary/10 text-primary">
                      <span class="material-symbols-outlined text-[18px]!">person</span>
                    </div>
                    <span class="truncate text-sm font-medium text-foreground">${escapeHtml(employee.name)}</span>
                  </a>
                `).join("")}
              </div>
            ` : `<p class="text-sm text-muted-foreground">${translate("No employees assigned")}</p>`}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_employee_group_path(companyId, group.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Employee Group")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

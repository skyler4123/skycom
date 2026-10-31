import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EmployeeGroups_IndexController extends Companies_LayoutController {
  // Employee Groups dashboard — table hydrates from the index JSON. Search and
  // filters follow the active TableConfig, like Departments.
  // Depends on BE: Companies::EmployeeGroupsController#index (list + q/filters)
  // Endpoints: GET <pathname>.json?category_id&q&filters[key]
  // Docs: docs/DYNAMIC_TABLE.md §2.5, docs/HR.md
  static targets = ["employeeGroupsList"]

  /** @type {(EmployeeGroup & { manager: Employee | null, branch: Branch | null, category: Category | null, employees_count: number })[]} */
  employeeGroups = []

  async connect() {
    super.connect()

    this.categoryIdValue = new URLSearchParams(window.location.search).get("category_id") || this.defaultFilterCategory()?.id
    this.resolveCategoryContext()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      if (!urlParams.get("category_id") && this.categoryIdValue) urlParams.set("category_id", this.categoryIdValue)

      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.employeeGroups = response.employee_groups || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load employee groups")}${detail ? ": " + detail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  employeeGroupsCategories() {
    return currentCategories().filter(c => c.resource_name === "employee_groups")
  }

  defaultFilterCategory() {
    return this.employeeGroupsCategories()[0]
  }

  // The client cache can arrive after connect(); resolve again before render so
  // a first visit still picks up the TableConfig and category filter.
  resolveCategoryContext() {
    if (!this.categoryIdValue) this.categoryIdValue = this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryIdValue)
    if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id

    const tableConfig = currentTableConfigs().find(c => c.property_mapping_id === this.propertyMappingIdValue)
    if (tableConfig) this.tableConfigIdValue = tableConfig.id
  }

  contentHTML() {
    this.resolveCategoryContext()

    const categoryFilter = this.employeeGroupsCategories()
    const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id

    const tableConfig = this.currentTableConfig()
    const propertyMapping = this.currentPropertyMapping()

    const fallbackColumns = [
      { key: "name", name: translate("Name"), search: true },
      { key: "code", name: translate("Code"), search: true },
      { key: "branch", name: translate("Branch") },
      { key: "manager", name: translate("Manager") },
      { key: "employees_count", name: translate("Members") }
    ]

    const rawColumns = tableConfig?.metadata?.columns || fallbackColumns
    const visibleColumns = rawColumns.filter(col => col.visible !== false)

    this.ensureColumn(visibleColumns, "manager", translate("Manager"), "name")
    this.ensureColumn(visibleColumns, "employees_count", translate("Members"), "manager")

    if (!visibleColumns.some(c => c.key === "category")) {
      const nameIdx = visibleColumns.findIndex(c => c.key === "name")
      if (nameIdx >= 0) visibleColumns.splice(nameIdx + 1, 0, { key: "category", name: translate("Category") })
    }

    const mappingLookup = (propertyMapping?.metadata?.properties || []).reduce((acc, field) => {
      acc[field.key] = field
      return acc
    }, {})

    const urlParams = new URLSearchParams(window.location.search)
    const searchHTML = dynamicSearchHTML({
      searchCols: rawColumns.filter(c => c.search === true),
      urlParams
    })
    const filtersHTML = dynamicFiltersHTML({
      filterCols: rawColumns.filter(c => c.filter && typeof c.filter === "object" && c.filter.type && c.filter.active !== false),
      urlParams,
      mappingLookup
    })

    const companyId = currentCompany().id

    return `
      <div class="p-4 overflow-y-auto" data-action="filter:changed@window->${this.identifier}#handleFilter">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          ${this.renderTableTitle()}

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                ${searchHTML}
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Category")}</label>
                  <select name="category_id"
                    class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
                  </select>
                </div>
                ${filtersHTML}
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]!">search</span>
                    ${translate("Search")}
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_employee_group_path(companyId)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add")}
              </a>
            </form>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.employeeGroups,
              columns: visibleColumns,
              identifier: this.identifier,
              target: "employeeGroupsList",
              mappingLookup,
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-4">
                    <div class="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-primary text-[18px]!">group_work</span>
                    </div>
                    <a href="${Helpers.company_employee_group_path(companyId, record.id)}"
                      class="font-medium text-foreground overflow-visible whitespace-normal hover:text-primary transition-colors cursor-pointer">
                      ${escapeHtml(value) || translate("Unnamed Employee Group")}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${escapeHtml(value) || "—"}</span>`,
                branch: (value, record) => record.branch?.name
                  ? `<span class="text-sm text-muted-foreground">${escapeHtml(record.branch.name)}</span>`
                  : `<span class="text-muted-foreground/60">—</span>`,
                manager: (value, record) => record.manager?.name
                  ? `<a href="${Helpers.company_employee_path(companyId, record.manager.id)}"
                       class="text-sm font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                       ${escapeHtml(record.manager.name)}
                     </a>`
                  : `<span class="text-muted-foreground/60">${translate("No manager")}</span>`,
                employees_count: (value) => `<span class="inline-flex items-center justify-center min-w-7 h-7 px-2 rounded-full bg-primary/10 text-primary text-xs font-bold">${Number(value) || 0}</span>`,
                category: (value, record) => record.category?.name
                  ? `<span class="text-sm text-muted-foreground">${escapeHtml(record.category.name)}</span>`
                  : `<span class="text-muted-foreground/60">—</span>`
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_company_employee_group_path(companyId, record.id)}"
                    ${tooltip(translate("Edit"))}
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

  // Core columns stay visible even when a custom TableConfig omits them.
  ensureColumn(columns, key, name, afterKey) {
    if (columns.some(column => column.key === key)) return

    const anchorIndex = columns.findIndex(column => column.key === afterKey)
    const insertAt = anchorIndex >= 0 ? anchorIndex + 1 : columns.length
    columns.splice(insertAt, 0, { key, name })
  }
}

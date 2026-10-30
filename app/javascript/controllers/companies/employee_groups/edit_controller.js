import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_EmployeeGroups_EditController extends Companies_LayoutController {
  // Edit Employee Group — prefilled core fields, manager/member assignment and
  // dynamic property fields. The manager is always enrolled server-side.
  // Depends on BE: Companies::EmployeeGroupsController#edit + #update
  // Endpoints: GET company_employee_group_path.json, PATCH company_employee_group_path
  // Docs: docs/HR.md, docs/DYNAMIC_TABLE.md §4
  /** @type {(EmployeeGroup & { manager: Employee | null, branch: Branch | null, category: Category | null, employees: Employee[], employee_ids: string[] }) | null} */
  employeeGroup = null

  /** @type {Array<{key: string, name: string, type: string}>} */
  propertyMetadata = []

  /** @type {Array<{id: string, name: string, branch_id: string}>} */
  employees = []

  /** @type {Array<{id: string, name: string}>} */
  branches = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.employeeGroup = response.employee_group
      this.employees = response.employees || []
      this.branches = response.branches || []
      this.employeeIds = this.employeeGroup?.employee_ids || (this.employeeGroup?.employees || []).map(employee => employee.id)

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

  onManagerChange(event) {
    const managerId = event.target.value
    if (!managerId) return

    const checkbox = this.element.querySelector(`input[name="employee_group[employee_ids][]"][value="${managerId}"]`)
    if (checkbox) checkbox.checked = true
  }

  filterEmployees(event) {
    const query = event.target.value.toLowerCase().trim()

    this.element.querySelectorAll("[data-employee-option]").forEach((label) => {
      label.classList.toggle("hidden", !label.dataset.employeeName.includes(query))
    })
  }

  isEmployeeChecked(employeeId) {
    const selectedIds = this.employeeIds || []
    return selectedIds.map(String).includes(String(employeeId)) || String(employeeId) === String(this.employeeGroup?.manager_id)
  }

  renderField(field) {
    const { key, name, type } = field
    const label = escapeHtml(name)
    const value = this.employeeGroup?.[key]
    const baseClass = "w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"

    switch (type) {
      case "boolean":
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="employee_group[${key}]" value="false">
            <input type="checkbox" name="employee_group[${key}]" value="true" ${value ? "checked" : ""}
              class="h-5 w-5 rounded border-line text-primary cursor-pointer">
            <span class="text-sm text-foreground">${label}</span>
          </div>
        `
      case "integer":
      case "decimal":
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="number" name="employee_group[${key}]" step="${type === "decimal" ? "0.01" : "1"}" value="${escapeHtml(value ?? "")}"
              class="${baseClass}">
          </div>
        `
      case "datetime":
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="employee_group[${key}]" value="${escapeHtml(value ?? "")}" class="${baseClass}">
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="text" name="employee_group[${key}]" value="${escapeHtml(value ?? "")}" class="${baseClass}">
          </div>
        `
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ""

    return `
      <div class="border-t border-line pt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => this.renderField(field)).join("")}
        </div>
      </div>
    `
  }

  employeeCheckboxesHTML() {
    if (this.employees.length === 0) {
      return `<p class="text-sm text-muted-foreground">${translate("No employees assigned")}</p>`
    }

    return `
      <div class="space-y-3">
        <input type="search" placeholder="${translate("Search employees...")}"
          data-action="input->${this.identifier}#filterEmployees"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground placeholder:text-muted-foreground">
        <input type="hidden" name="employee_group[employee_ids][]" value="">
        <div class="grid grid-cols-1 gap-2 max-h-56 overflow-y-auto border border-line rounded-lg p-3 sm:grid-cols-2">
          ${this.employees.map(employee => `
            <label data-employee-option data-employee-name="${escapeHtml(employee.name?.toLowerCase())}"
              class="flex items-center gap-2 text-sm text-foreground cursor-pointer">
              <input type="checkbox" name="employee_group[employee_ids][]" value="${employee.id}"
                ${this.isEmployeeChecked(employee.id) ? "checked" : ""}
                class="h-4 w-4 rounded border-line text-primary cursor-pointer">
              <span class="truncate">${escapeHtml(employee.name) || employee.id}</span>
            </label>
          `).join("")}
        </div>
      </div>
    `
  }

  contentHTML() {
    const group = this.employeeGroup
    if (!group) return `<div class="p-8 text-center">${translate("Employee Group not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const managerOptions = selectOptionsHTML(
      cloneNewKey(this.employees, "id", "value").map(employee => ({ ...employee, name: escapeHtml(employee.name) })),
      group.manager_id,
      translate("No manager")
    )
    const branchOptions = selectOptionsHTML(
      cloneNewKey(this.branches, "id", "value").map(branch => ({ ...branch, name: escapeHtml(branch.name) })),
      group.branch_id,
      translate("Select branch")
    )

    const fields = `
      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Employee Group")}</h2>
          <p class="text-sm text-muted-foreground">${escapeHtml(group.name)}</p>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
          <input type="text" value="${escapeHtml(group.category?.name)}" disabled
            class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
          <input type="hidden" name="employee_group[category_id]" value="${group.category_id}">
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div class="sm:col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Group Name")}</label>
            <input type="text" name="employee_group[name]" value="${escapeHtml(group.name)}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
          </div>

          <div class="sm:col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="employee_group[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">${escapeHtml(group.description)}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Email")}</label>
            <input type="email" name="employee_group[email]" value="${escapeHtml(group.email)}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Branch")}</label>
            <select name="employee_group[branch_id]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${branchOptions}
            </select>
          </div>

          <div class="sm:col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Manager")}</label>
            <select name="employee_group[manager_id]" data-action="change->${this.identifier}#onManagerChange"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${managerOptions}
            </select>
            <p class="text-xs text-muted-foreground">${translate("The selected manager is automatically added as a member.")}</p>
          </div>
        </div>

        <div class="border-t border-line pt-6 space-y-3">
          <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider">${translate("Members")}</h3>
          ${this.employeeCheckboxesHTML()}
        </div>

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end gap-3 pt-6 border-t border-line">
          <a href="${Helpers.company_employee_group_path(companyId, group.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_employee_group_path(companyId, group.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}

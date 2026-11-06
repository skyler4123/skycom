import { Controller } from "@hotwired/stimulus"

export default class Companies_Exams_AssignmentPanelController extends Controller {
  // Employee assignment panel mounted on the exam edit page.
  // Depends on BE: Companies::ExamAssignmentsController#index/#create
  // Endpoints: GET /companies/:id/exams/:id/assignments.json,
  //            POST /companies/:id/exams/:id/assignments
  // Docs: docs/EXAMS.md

  static values = {
    examId: String,
    examStatus: String
  }

  employees = []
  pagination = {}
  filters = {}
  selectedIds = new Set()
  query = ""
  departmentId = ""
  employeeGroupId = ""
  branchId = ""
  page = 1
  initialized = false
  searchTimer = null

  connect() {
    if (this.examStatusValue !== "published") {
      this.element.innerHTML = this.disabledHTML()
      return
    }

    this.element.innerHTML = this.contentHTML()
    this.loadEmployees()
  }

  companyId() {
    return currentCompany()?.id
  }

  assignmentsPath() {
    return Helpers.company_exam_assignments_path(this.companyId(), this.examIdValue)
  }

  disabledHTML() {
    return `
      <div class="rounded-xl border border-warning/40 bg-warning/10 p-4">
        <div class="flex items-start gap-3">
          <span class="material-symbols-outlined text-warning">info</span>
          <div>
            <h3 class="text-sm font-bold text-warning">${translate("Employees")}</h3>
            <p class="mt-1 text-sm text-warning">${translate("This exam is not published. Publish it before assigning employees.")}</p>
          </div>
        </div>
      </div>
    `
  }

  contentHTML() {
    const departments = (this.filters.departments || []).map(entry => ({ value: entry.id, name: entry.name }))
    const groups = (this.filters.employee_groups || []).map(entry => ({ value: entry.id, name: entry.name }))
    const branches = (this.filters.branches || []).map(entry => ({ value: entry.id, name: entry.name }))

    return `
      <div class="rounded-xl border border-line bg-card p-4">
        <div class="mb-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Employees")}</h3>
            <p class="text-xs text-muted-foreground">${translate("Only published exams can be assigned. Select employees and assign them below.")}</p>
          </div>
          <div class="flex items-center gap-2 text-xs text-muted-foreground">
            <span data-assignment-selected-count>${this.selectedIds.size}</span>
            <span>${translate("selected")}</span>
            <button type="button" data-action="click->${this.identifier}#clearSelection"
              class="rounded-lg px-2 py-1 font-medium text-muted-foreground hover:bg-muted hover:text-foreground">
              ${translate("Clear")}
            </button>
          </div>
        </div>

        <div class="mb-4 grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-4">
          <input type="search" value="${escapeHtml(this.query)}" placeholder="${translate("Search employees...")}"
            data-action="input->${this.identifier}#onSearch"
            class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground">
          <select data-action="change->${this.identifier}#onDepartmentChange"
            class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground">
            ${selectOptionsHTML(departments, this.departmentId, translate("All Departments"))}
          </select>
          <select data-action="change->${this.identifier}#onGroupChange"
            class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground">
            ${selectOptionsHTML(groups, this.employeeGroupId, translate("All Groups"))}
          </select>
          <select data-action="change->${this.identifier}#onBranchChange"
            class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground">
            ${selectOptionsHTML(branches, this.branchId, translate("All Branches"))}
          </select>
        </div>

        <div data-assignment-results>
          <p class="p-4 text-sm text-muted-foreground">${translate("Loading...")}</p>
        </div>
      </div>
    `
  }

  async loadEmployees() {
    try {
      const params = new URLSearchParams()
      if (this.query) params.set("q", this.query)
      if (this.departmentId) params.set("department_id", this.departmentId)
      if (this.employeeGroupId) params.set("employee_group_id", this.employeeGroupId)
      if (this.branchId) params.set("branch_id", this.branchId)
      params.set("page[page]", this.page)

      const response = await fetchJson(`${this.assignmentsPath()}.json?${params.toString()}`)
      this.employees = response.employees || []
      this.pagination = response.pagination || {}
      this.filters = response.filters || {}

      if (!this.initialized) {
        this.initialized = true
        this.element.innerHTML = this.contentHTML()
      }
      this.renderResults()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  statusLabel(status) {
    const labels = {
      not_assigned: translate("Not Assigned"),
      assigned: translate("Assigned"),
      in_progress: translate("In Progress"),
      submitted: translate("Submitted"),
      passed: translate("Passed"),
      failed: translate("Failed"),
      expired: translate("Expired")
    }
    return labels[status] || status
  }

  statusClasses(status) {
    switch (status) {
      case "passed": return "bg-success/10 text-success"
      case "failed": return "bg-danger/10 text-danger"
      case "in_progress":
      case "expired": return "bg-warning/10 text-warning"
      case "submitted":
      case "assigned": return "bg-primary/10 text-primary"
      default: return "bg-muted text-muted-foreground"
    }
  }

  renderResults() {
    const container = this.element.querySelector("[data-assignment-results]")
    if (!container) return

    container.innerHTML = this.resultsHTML()
    this.updateSelectedCount()
  }

  resultsHTML() {
    const selectable = this.employees.filter(employee => employee.assignment_status === "not_assigned")
    const allSelected = selectable.length > 0 && selectable.every(employee => this.selectedIds.has(String(employee.id)))

    return `
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-left">
          <thead>
            <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
              <th class="px-3 py-3">
                <input type="checkbox" ${allSelected ? "checked" : ""} ${selectable.length === 0 ? "disabled" : ""}
                  data-action="change->${this.identifier}#selectAllOnPage"
                  class="h-4 w-4 rounded border-line text-primary">
              </th>
              <th class="px-3 py-3 font-medium">${translate("Employee")}</th>
              <th class="px-3 py-3 font-medium">${translate("Department")}</th>
              <th class="px-3 py-3 font-medium">${translate("Branch")}</th>
              <th class="px-3 py-3 text-center font-medium">${translate("Status")}</th>
              <th class="px-3 py-3 text-center font-medium">${translate("Attempts Used")}</th>
              <th class="px-3 py-3 text-center font-medium">${translate("Best Score")}</th>
            </tr>
          </thead>
          <tbody>
            ${this.employees.map(employee => {
              const selectable = employee.assignment_status === "not_assigned"
              const selected = this.selectedIds.has(String(employee.id))
              return `
                <tr class="border-b border-line/70 hover:bg-muted/40">
                  <td class="px-3 py-3">
                    <input type="checkbox" value="${employee.id}" ${selected ? "checked" : ""} ${selectable ? "" : "disabled"}
                      data-action="change->${this.identifier}#toggleSelection" data-employee-id="${employee.id}"
                      class="h-4 w-4 rounded border-line text-primary disabled:cursor-not-allowed disabled:opacity-40">
                  </td>
                  <td class="px-3 py-3">
                    <p class="text-sm font-medium text-foreground">${escapeHtml(employee.name)}</p>
                    <p class="text-xs text-muted-foreground">${escapeHtml(employee.email || "")}</p>
                  </td>
                  <td class="px-3 py-3 text-xs text-muted-foreground">
                    ${escapeHtml((employee.departments || []).map(department => department.name).join(", ") || "—")}
                  </td>
                  <td class="px-3 py-3 text-xs text-muted-foreground">${escapeHtml(employee.branch_name || "—")}</td>
                  <td class="px-3 py-3 text-center">
                    <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses(employee.assignment_status)}">
                      ${this.statusLabel(employee.assignment_status)}
                    </span>
                  </td>
                  <td class="px-3 py-3 text-center text-sm text-foreground">${employee.attempts_used || 0}</td>
                  <td class="px-3 py-3 text-center text-sm text-foreground">
                    ${employee.best_score === null || employee.best_score === undefined ? "—" : Number(employee.best_score).toFixed(2)}
                  </td>
                </tr>
              `
            }).join("")}
          </tbody>
        </table>
      </div>

      ${this.employees.length === 0 ? `<p class="p-4 text-sm text-muted-foreground">${translate("No employees match these filters.")}</p>` : ""}

      <div class="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-2">
          <button type="button" data-action="click->${this.identifier}#previousPage" ${this.pagination.page > 1 ? "" : "disabled"}
            class="rounded-lg border border-line px-2 py-1 text-sm text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-40">
            <span class="material-symbols-outlined text-[18px]!">chevron_left</span>
          </button>
          <span class="text-xs text-muted-foreground">
            ${translate("Page")} ${this.pagination.page || 1} / ${this.pagination.last || 1}
          </span>
          <button type="button" data-action="click->${this.identifier}#nextPage" ${this.pagination.page < this.pagination.last ? "" : "disabled"}
            class="rounded-lg border border-line px-2 py-1 text-sm text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-40">
            <span class="material-symbols-outlined text-[18px]!">chevron_right</span>
          </button>
        </div>

        <button type="button" data-action="click->${this.identifier}#assignSelected" data-assignment-assign
          class="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50">
          <span class="material-symbols-outlined text-[18px]!">person_add</span>
          ${translate("Assign Selected")}
        </button>
      </div>
    `
  }

  updateSelectedCount() {
    const counter = this.element.querySelector("[data-assignment-selected-count]")
    if (counter) counter.textContent = this.selectedIds.size

    const button = this.element.querySelector("[data-assignment-assign]")
    if (button) button.disabled = this.selectedIds.size === 0
  }

  onSearch(event) {
    this.query = event.target.value
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => {
      this.page = 1
      this.loadEmployees()
    }, 300)
  }

  onDepartmentChange(event) {
    this.departmentId = event.target.value
    this.page = 1
    this.loadEmployees()
  }

  onGroupChange(event) {
    this.employeeGroupId = event.target.value
    this.page = 1
    this.loadEmployees()
  }

  onBranchChange(event) {
    this.branchId = event.target.value
    this.page = 1
    this.loadEmployees()
  }

  toggleSelection(event) {
    const id = String(event.currentTarget.dataset.employeeId)
    if (event.currentTarget.checked) {
      this.selectedIds.add(id)
    } else {
      this.selectedIds.delete(id)
    }
    this.renderResults()
  }

  selectAllOnPage(event) {
    const selectable = this.employees.filter(employee => employee.assignment_status === "not_assigned")
    if (event.currentTarget.checked) {
      selectable.forEach(employee => this.selectedIds.add(String(employee.id)))
    } else {
      selectable.forEach(employee => this.selectedIds.delete(String(employee.id)))
    }
    this.renderResults()
  }

  clearSelection() {
    this.selectedIds.clear()
    this.renderResults()
  }

  previousPage() {
    if (this.pagination.page <= 1) return
    this.page = this.pagination.page - 1
    this.loadEmployees()
  }

  nextPage() {
    if (this.pagination.page >= this.pagination.last) return
    this.page = this.pagination.page + 1
    this.loadEmployees()
  }

  async assignSelected() {
    if (this.selectedIds.size === 0) return

    try {
      const response = await fetchJson(`${this.assignmentsPath()}.json`, {
        method: "POST",
        body: { employee_ids: [ ...this.selectedIds ] }
      })
      toast({ type: "success", message: response.message })
      this.selectedIds.clear()
      this.page = 1
      await this.loadEmployees()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }
}

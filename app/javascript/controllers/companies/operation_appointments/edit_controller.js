import Companies_LayoutController from "controllers/companies/layout_controller"

// Shared edit page for branch and warehouse operation appointments.
// Roles may narrow the Operation roles; other metadata is preserved but never
// exposed as raw JSON. Subclasses provide recordPath()/payloadKey().
// Depends on BE: Companies::BranchOperationAppointmentsController#show/#update,
//                Companies::OperationWarehouseAppointmentsController#show/#update
export default class Companies_OperationAppointments_EditController extends Companies_LayoutController {
  static targets = ["rolesPicker", "rolesTrigger", "rolesSummary", "rolesMenu"]

  /** @type {any | null} */ appointment = null

  async connect() {
    super.connect()

    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this.handleDocumentClick)
    document.addEventListener("keydown", this.handleKeydown)

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const appointmentId = pathParts[pathParts.length - 2]

    try {
      const response = await fetchJson(`${this.recordPath(companyId, appointmentId)}.json`)
      this.appointment = response.appointment

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load operation.")}</div>`
          return true
        }
        return false
      })
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleDocumentClick(event) {
    if (!this.hasRolesMenuTarget || this.rolesMenuTarget.classList.contains("hidden")) return
    if (this.rolesPickerTarget.contains(event.target)) return

    this.closeRolesMenu()
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.closeRolesMenu()
  }

  toggleRolesMenu(event) {
    event.preventDefault()

    const hidden = this.rolesMenuTarget.classList.toggle("hidden")
    this.rolesTriggerTarget.setAttribute("aria-expanded", String(!hidden))
  }

  closeRolesMenu() {
    if (!this.hasRolesMenuTarget) return

    this.rolesMenuTarget.classList.add("hidden")
    this.rolesTriggerTarget.setAttribute("aria-expanded", "false")
  }

  selectedRoleNames() {
    return Array.from(this.element.querySelectorAll('input[name="operation_appointment_roles[]"]'))
      .filter(input => input.checked)
      .map(input => input.value)
  }

  initialRoles() {
    return Array.isArray(this.appointment?.metadata?.roles) ? this.appointment.metadata.roles.filter(role => typeof role === "string") : []
  }

  roleOptions(selectedRoles) {
    const operationRoles = Array.isArray(this.appointment?.operation?.metadata?.roles) ? this.appointment.operation.metadata.roles : []
    const cached = operationRoles.length > 0 ? operationRoles : (currentRoles() || []).map(role => role.name).filter(Boolean)

    return [...new Set([...cached, ...selectedRoles])].sort((a, b) => a.localeCompare(b))
  }

  emptyRolesLabel() {
    const operationRoles = Array.isArray(this.appointment?.operation?.metadata?.roles) ? this.appointment.operation.metadata.roles : []

    return operationRoles.length > 0 ? translate("Inherit Operation roles") : translate("All roles")
  }

  roleChipHTML(name) {
    return `
      <span class="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary">
        ${Helpers.escapeHtml(name)}
        <button type="button" data-action="click->${this.identifier}#removeRole" data-${this.identifier}-role-param="${Helpers.escapeHtml(name)}" aria-label="${translate("Remove")} ${Helpers.escapeHtml(name)}" class="inline-flex items-center justify-center text-primary hover:text-danger cursor-pointer">
          <span class="material-symbols-outlined text-[14px]">close</span>
        </button>
      </span>
    `
  }

  rolePickerHTML(selectedRoles) {
    const options = this.roleOptions(selectedRoles)
    const summary = selectedRoles.length === 0
      ? `<span class="text-muted-foreground">${this.emptyRolesLabel()}</span>`
      : selectedRoles.map(name => this.roleChipHTML(name)).join("")
    const optionsHTML = options.length === 0
      ? `<p class="px-2 py-2 text-sm text-muted-foreground">${translate("No roles available. Create a role first.")}</p>`
      : options.map(name => `
          <label class="flex items-center gap-2 rounded-md px-2 py-1.5 text-sm text-foreground hover:bg-muted cursor-pointer">
            <input type="checkbox" name="operation_appointment_roles[]" value="${Helpers.escapeHtml(name)}" ${selectedRoles.includes(name) ? "checked" : ""} data-action="change->${this.identifier}#syncRoleSelection" class="h-4 w-4 rounded border-line text-primary cursor-pointer">
            <span class="truncate">${Helpers.escapeHtml(name)}</span>
          </label>
        `).join("")

    return `
      <div class="space-y-1">
        <label class="text-xs font-medium text-muted-foreground">${translate("Access Roles")}</label>
        <div class="relative" data-${this.identifier}-target="rolesPicker">
          <div class="flex min-h-10 w-full flex-wrap items-center gap-2 rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus-within:ring-2 focus-within:ring-primary" data-action="click->${this.identifier}#toggleRolesMenu">
            <div class="flex flex-1 flex-wrap items-center gap-1" data-${this.identifier}-target="rolesSummary">
              ${summary}
            </div>
            <button
              type="button"
              aria-haspopup="listbox"
              aria-expanded="false"
              aria-label="${translate("Access Roles")}"
              data-${this.identifier}-target="rolesTrigger"
              class="inline-flex items-center justify-center rounded-md p-0.5 text-muted-foreground hover:bg-muted cursor-pointer"
            >
              <span class="material-symbols-outlined text-[20px]">expand_more</span>
            </button>
          </div>
          <div class="absolute z-30 mt-1 hidden max-h-64 w-full overflow-y-auto rounded-lg border border-line bg-card p-2 shadow-lg" data-${this.identifier}-target="rolesMenu">
            ${optionsHTML}
          </div>
        </div>
        <p class="text-xs text-muted-foreground">${translate("Roles can only narrow access. Leave empty to inherit the Operation roles.")}</p>
      </div>
    `
  }

  syncRoleSelection() {
    if (!this.hasRolesSummaryTarget) return

    const selected = this.selectedRoleNames()
    this.rolesSummaryTarget.innerHTML = selected.length === 0
      ? `<span class="text-muted-foreground">${this.emptyRolesLabel()}</span>`
      : selected.map(name => this.roleChipHTML(name)).join("")
  }

  removeRole(event) {
    event.preventDefault()
    event.stopPropagation()

    const input = Array.from(this.element.querySelectorAll('input[name="operation_appointment_roles[]"]')).find(el => el.value === event.params.role)
    if (input) input.checked = false

    this.syncRoleSelection()
  }

  recordPath() {
    throw new Error("Subclass must implement recordPath(companyId, appointmentId)")
  }

  payloadKey() {
    throw new Error("Subclass must implement payloadKey()")
  }

  contentHTML() {
    const appointment = this.appointment
    if (!appointment) return `<div class="p-8 text-center">${translate("Operation not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const operation = appointment.operation || {}
    const selectedRoles = this.initialRoles()
    const status = appointment.workflow_status || "active"

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Operation")}</h2>
          <p class="text-sm text-muted-foreground">${Helpers.escapeHtml(operation.name || "")} · ${Helpers.escapeHtml(appointment.location?.name || "")}</p>
        </div>

        <div class="rounded-lg border border-line bg-muted/40 p-3 text-xs text-muted-foreground">
          ${translate("Settings here apply to this location. Saving the Operation config resets them.")}
        </div>

        ${this.rolePickerHTML(selectedRoles)}

        <div class="space-y-1">
          <label for="workflow_status" class="text-xs font-medium text-muted-foreground">${translate("Status")}</label>
          <select id="workflow_status" name="workflow_status"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
            <option value="active" ${status === "active" ? "selected" : ""}>${translate("Active")}</option>
            <option value="inactive" ${status === "inactive" ? "selected" : ""}>${translate("Inactive")}</option>
          </select>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${this.recordPath(companyId, appointment.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: this.recordPath(companyId, appointment.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line max-w-3xl" data-action="submit->${this.identifier}#handleSubmit"`,
          html: fields
        })}
      </div>
    `
  }

  async handleSubmit(event) {
    event.preventDefault()

    const formData = new FormData(event.target)
    const metadata = {
      ...(this.appointment?.metadata || {}),
      roles: formData.getAll("operation_appointment_roles[]")
    }

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const appointmentId = pathParts[pathParts.length - 2]
    const workflowStatus = formData.get("workflow_status")

    try {
      const response = await fetchJson(this.recordPath(companyId, appointmentId), {
        method: "PATCH",
        body: {
          [this.payloadKey()]: {
            metadata,
            workflow_status: workflowStatus
          }
        }
      })
      navigateThenToast(this.recordPath(companyId, appointmentId), {
        type: "success",
        message: response.message
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update operation.") })
    }
  }
}

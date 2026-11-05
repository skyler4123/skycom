import Companies_LayoutController from "controllers/companies/layout_controller"

// Companies_OperationConfigs_EditController — company-wide Operation access-role editor.
// Only operation.metadata.roles is editable here; every other metadata key is preserved.
// Depends on BE: Companies::OperationConfigsController#show (load) + #update
// Endpoints: GET /companies/:company_id/operation_configs/:id(.json),
//            PATCH /companies/:company_id/operation_configs/:id
export default class Companies_OperationConfigs_EditController extends Companies_LayoutController {
  static targets = ["rolesPicker", "rolesTrigger", "rolesSummary", "rolesMenu"]

  /** @type {any | null} */ operationConfig = null

  async connect() {
    super.connect()

    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this.handleDocumentClick)
    document.addEventListener("keydown", this.handleKeydown)

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const operationConfigId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.company_operation_config_path(companyId, operationConfigId)}.json`)
      this.operationConfig = response.operation_config

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load operation config.")}</div>`
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
    return Array.from(this.element.querySelectorAll('input[name="operation[metadata][roles][]"]'))
      .filter(input => input.checked)
      .map(input => input.value)
  }

  roleOptions(selectedRoles) {
    const cached = (currentRoles() || []).map(role => role.name).filter(Boolean)

    return [...new Set([...cached, ...selectedRoles])].sort((a, b) => a.localeCompare(b))
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
      ? `<span class="text-muted-foreground">${translate("All roles")}</span>`
      : selectedRoles.map(name => this.roleChipHTML(name)).join("")
    const optionsHTML = options.length === 0
      ? `<p class="px-2 py-2 text-sm text-muted-foreground">${translate("No roles available. Create a role first.")}</p>`
      : options.map(name => `
          <label class="flex items-center gap-2 rounded-md px-2 py-1.5 text-sm text-foreground hover:bg-muted cursor-pointer">
            <input type="checkbox" name="operation[metadata][roles][]" value="${Helpers.escapeHtml(name)}" ${selectedRoles.includes(name) ? "checked" : ""} data-action="change->${this.identifier}#syncRoleSelection" class="h-4 w-4 rounded border-line text-primary cursor-pointer">
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
        <p class="text-xs text-muted-foreground">${translate("Leave empty to allow every role to use this operation.")}</p>
      </div>
    `
  }

  syncRoleSelection() {
    if (!this.hasRolesSummaryTarget) return

    const selected = this.selectedRoleNames()
    this.rolesSummaryTarget.innerHTML = selected.length === 0
      ? `<span class="text-muted-foreground">${translate("All roles")}</span>`
      : selected.map(name => this.roleChipHTML(name)).join("")
  }

  removeRole(event) {
    event.preventDefault()
    event.stopPropagation()

    const input = Array.from(this.element.querySelectorAll('input[name="operation[metadata][roles][]"]')).find(el => el.value === event.params.role)
    if (input) input.checked = false

    this.syncRoleSelection()
  }

  contentHTML() {
    const c = this.operationConfig
    if (!c) return `<div class="p-8 text-center">${translate("Operation config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const selectedRoles = Array.isArray(c.metadata?.roles)
      ? c.metadata.roles.filter(role => typeof role === "string")
      : []

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Config")}</h2>
          <p class="text-sm text-muted-foreground">${Helpers.escapeHtml(c.name || "")}</p>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Type")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml((c.operation_type || "—").replace(/_/g, " ").toUpperCase())}</p>
          </div>
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Resolution")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml(c.resolution || "—")}</p>
          </div>
        </div>

        <div class="rounded-lg border border-warning/20 bg-warning/10 p-3 text-xs text-warning">
          ${translate("Saving config here resets every branch and warehouse config.")}
        </div>

        ${this.rolePickerHTML(selectedRoles)}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_operation_config_path(companyId, c.id)}"
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
          action: Helpers.company_operation_config_path(companyId, c.id),
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
      ...(this.operationConfig.metadata || {}),
      roles: formData.getAll("operation[metadata][roles][]")
    }

    const companyId = window.location.pathname.split("/")[2]
    const operationConfigId = window.location.pathname.split("/")[4]

    try {
      const response = await fetchJson(Helpers.company_operation_config_path(companyId, operationConfigId), {
        method: "PATCH",
        body: { operation: { metadata } }
      })
      navigateThenToast(Helpers.company_operation_config_path(companyId, operationConfigId), {
        type: "success",
        message: response.message
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update operation config.") })
    }
  }
}

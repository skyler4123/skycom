import Companies_LayoutController from "controllers/companies/layout_controller"

// Companies_Operations_IndexController — operation list, one row per branch/warehouse location.
// Depends on BE: Companies::OperationsController#index
// Endpoints: GET /companies/:company_id/operations(.json?q=&operation_type=&workflow_status=&location=)
export default class Companies_Operations_IndexController extends Companies_LayoutController {
  /** @type {any[]} */ appointments = []

  /** @type {any} */ filters = {}

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.appointments = response.operation_appointments || []
      this.filters = response.filters || {}
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load operations")}${detail ? ": " + detail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  translatedOptions(options) {
    return (options || []).map(option => ({ value: option.value, name: translate(option.name) }))
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const locationOptions = (this.filters.locations || []).map(location => ({
      value: location.value,
      name: `${Helpers.escapeHtml(location.name)} (${translate(location.kind === "branch" ? "Branch" : "Warehouse")})`
    }))

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col gap-5">
          <div class="flex flex-col gap-1">
            <h2 class="text-xl font-bold text-foreground">${translate("Operations")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Each operation is available at your branches and warehouses. Launch it, or edit the settings for that location.")}</p>
          </div>

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Search")}</label>
              <input type="text" name="q" value="${Helpers.escapeHtml(urlParams.get("q") || "")}" placeholder="${translate("Search operations...")}" class="pl-3 pr-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground">
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Type")}</label>
              <select name="operation_type" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(this.translatedOptions(this.filters.operation_types), urlParams.get("operation_type"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Status")}</label>
              <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(this.translatedOptions(this.filters.statuses), urlParams.get("workflow_status"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Location")}</label>
              <select name="location" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(locationOptions, urlParams.get("location"), translate("All"))}
              </select>
            </div>
            <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">search</span>
              ${translate("Search")}
            </button>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-line">
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Operation")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Type")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Location")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Resolution")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Status")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Access Roles")}</th>
                  <th class="text-right py-4 px-6 font-semibold text-foreground w-32">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.appointments.length === 0
                  ? `<tr><td colspan="7" class="py-8 text-center text-muted-foreground">${translate("No operations found.")}</td></tr>`
                  : this.appointments.map(appointment => this.rowHTML(appointment)).join("")}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }

  appointmentPath(companyId, appointment) {
    return appointment.kind === "branch"
      ? Helpers.branch_operation_appointment_path(companyId, appointment.id)
      : Helpers.operation_warehouse_appointment_path(companyId, appointment.id)
  }

  editAppointmentPath(companyId, appointment) {
    return appointment.kind === "branch"
      ? Helpers.edit_company_branch_operation_appointment_path(companyId, appointment.id)
      : Helpers.edit_company_operation_warehouse_appointment_path(companyId, appointment.id)
  }

  rowHTML(appointment) {
    const companyId = currentCompany().id
    const operation = appointment.operation || {}
    const active = appointment.workflow_status === "active"
    const canLaunch = active && appointment.accessible
    const launchReason = !appointment.accessible
      ? translate("You do not have access to this operation.")
      : translate("This operation is inactive.")
    const roles = Array.isArray(appointment.access_roles) ? appointment.access_roles : []

    return `
      <tr class="border-b border-line hover:bg-muted/50">
        <td class="py-4 px-6">
          <a href="${this.appointmentPath(companyId, appointment)}"
            class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
            ${Helpers.escapeHtml(operation.name || translate("Unnamed Operation"))}
          </a>
          <p class="font-mono text-xs text-muted-foreground">${Helpers.escapeHtml(operation.code || "—")}</p>
        </td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml((operation.operation_type || "—").replace(/_/g, " ").toUpperCase())}</td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml(appointment.location?.name || "—")}</td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml(operation.resolution || "—")}</td>
        <td class="py-4 px-6">${Helpers.statusBadge(appointment.workflow_status)}</td>
        <td class="py-4 px-6">
          ${roles.length === 0
            ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-line">${translate("All roles")}</span>`
            : roles.map(role => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary mr-1">${Helpers.escapeHtml(role)}</span>`).join("")}
        </td>
        <td class="py-4 px-6 text-right whitespace-nowrap">
          ${canLaunch
            ? `<a href="${Helpers.escapeHtml(appointment.launch_path)}" class="inline-flex items-center justify-center p-2 text-success hover:bg-success/10 rounded-lg cursor-pointer" ${tooltip(translate("Launch"))}>
                 <span class="material-symbols-outlined text-[20px]">open_in_new</span>
               </a>`
            : `<span class="inline-flex items-center justify-center p-2 text-muted-foreground/40 cursor-not-allowed" title="${Helpers.escapeHtml(launchReason)}" ${tooltip(launchReason)}>
                 <span class="material-symbols-outlined text-[20px]">open_in_new</span>
                 <span class="sr-only">${launchReason}</span>
               </span>`}
          <a href="${this.editAppointmentPath(companyId, appointment)}"
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer" ${tooltip(translate("Edit Config"))}>
            <span class="material-symbols-outlined text-[20px]">edit</span>
          </a>
        </td>
      </tr>
    `
  }
}

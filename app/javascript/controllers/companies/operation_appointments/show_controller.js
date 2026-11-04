import Companies_LayoutController from "controllers/companies/layout_controller"

// Shared detail page for branch and warehouse operation appointments.
// Subclasses provide recordPath()/editRecordPath().
// Depends on BE: Companies::BranchOperationAppointmentsController#show,
//                Companies::OperationWarehouseAppointmentsController#show
export default class Companies_OperationAppointments_ShowController extends Companies_LayoutController {
  /** @type {any | null} */ appointment = null

  get kind() {
    throw new Error("Subclass must implement kind")
  }

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const appointmentId = pathParts[pathParts.length - 1]

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load operation appointment.")}</div>`
          return true
        }
        return false
      })
    }
  }

  recordPath() {
    throw new Error("Subclass must implement recordPath(companyId, appointmentId)")
  }

  editRecordPath() {
    throw new Error("Subclass must implement editRecordPath(companyId, appointmentId)")
  }

  contentHTML() {
    const appointment = this.appointment
    if (!appointment) return `<div class="p-8 text-center">${translate("Operation appointment not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const operation = appointment.operation || {}
    const roles = Array.isArray(operation.metadata?.roles) ? operation.metadata.roles : []
    const metadata = JSON.stringify(appointment.metadata || {}, null, 2)
    const effectiveConfig = JSON.stringify(appointment.effective_config || {}, null, 2)
    const canLaunch = appointment.workflow_status === "active" && appointment.accessible

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_operations_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Operation Appointments")}
          </a>

          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div class="flex items-start gap-4">
              <div class="flex size-14 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
                <span class="material-symbols-outlined text-3xl">${this.kind === "branch" ? "storefront" : "warehouse"}</span>
              </div>
              <div>
                <p class="text-xs font-bold uppercase text-muted-foreground">${translate("Appointment config")} · ${translate(this.kind === "branch" ? "Branch" : "Warehouse")}</p>
                <h2 class="text-2xl font-black text-foreground">${Helpers.escapeHtml(operation.name || translate("Unnamed Operation"))}</h2>
                <p class="font-mono text-sm text-muted-foreground">${Helpers.escapeHtml(operation.code || "—")} · ${Helpers.escapeHtml(appointment.location?.name || "—")}</p>
              </div>
            </div>
            <div class="flex flex-wrap gap-2">
              ${Helpers.statusBadge(appointment.workflow_status)}
            </div>
          </div>

          <div class="rounded-lg border border-line bg-muted/40 p-3 text-xs text-muted-foreground mb-6">
            ${translate("Operation config overrides every appointment config.")}
          </div>

          <div class="grid grid-cols-1 gap-4 border-t border-line pt-6 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Type")}</p>
              <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml((operation.operation_type || "—").replace(/_/g, " ").toUpperCase())}</p>
            </div>

            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Resolution")}</p>
              <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml(operation.resolution || "—")}</p>
            </div>

            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Location")}</p>
              <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml(appointment.location?.name || "—")}</p>
            </div>

            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Access Roles")}</p>
              <div class="mt-1 flex flex-wrap gap-1">
                ${roles.length === 0
                  ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-line">${translate("All roles")}</span>`
                  : roles.map(role => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary">${Helpers.escapeHtml(role)}</span>`).join("")}
              </div>
            </div>
          </div>

          <div class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
            <div class="rounded-lg border border-line bg-muted/30 p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Metadata (JSON)")}</p>
              <pre class="mt-2 overflow-x-auto text-xs font-mono text-foreground">${Helpers.escapeHtml(metadata)}</pre>
            </div>

            <div class="rounded-lg border border-line bg-muted/30 p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Effective Config")}</p>
              <pre class="mt-2 overflow-x-auto text-xs font-mono text-foreground">${Helpers.escapeHtml(effectiveConfig)}</pre>
            </div>
          </div>

          <div class="mt-8 flex flex-wrap justify-end gap-3 pt-6 border-t border-line">
            ${canLaunch
              ? `<a href="${Helpers.escapeHtml(appointment.launch_path)}"
                   class="inline-flex items-center gap-2 px-6 py-2 border border-line text-foreground hover:bg-muted rounded-lg font-medium text-sm transition-colors cursor-pointer">
                   <span class="material-symbols-outlined text-[18px]">open_in_new</span>
                   ${translate("Launch")}
                 </a>`
              : ""}
            <a href="${this.editRecordPath(companyId, appointment.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Config")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

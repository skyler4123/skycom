import Companies_LayoutController from "controllers/companies/layout_controller"

// Shared edit page for branch and warehouse operation appointments.
// Subclasses provide recordPath()/payloadKey().
// Depends on BE: Companies::BranchOperationAppointmentsController#show/#update,
//                Companies::OperationWarehouseAppointmentsController#show/#update
export default class Companies_OperationAppointments_EditController extends Companies_LayoutController {
  /** @type {any | null} */ appointment = null

  async connect() {
    super.connect()

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

  payloadKey() {
    throw new Error("Subclass must implement payloadKey()")
  }

  contentHTML() {
    const appointment = this.appointment
    if (!appointment) return `<div class="p-8 text-center">${translate("Operation appointment not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const operation = appointment.operation || {}
    const metadata = JSON.stringify(appointment.metadata || {}, null, 2)
    const status = appointment.workflow_status || "active"

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Appointment config")}</h2>
          <p class="text-sm text-muted-foreground">${Helpers.escapeHtml(operation.name || "")} · ${Helpers.escapeHtml(appointment.location?.name || "")}</p>
        </div>

        <div class="rounded-lg border border-line bg-muted/40 p-3 text-xs text-muted-foreground">
          ${translate("Operation config overrides every appointment config.")}
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Metadata (JSON)")}</label>
          <textarea name="metadata" rows="10"
            class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none">${Helpers.escapeHtml(metadata)}</textarea>
        </div>

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

    let metadata
    try {
      metadata = JSON.parse(new FormData(event.target).get("metadata") || "{}")
    } catch {
      toast({ type: "error", message: translate("Invalid JSON") })
      return
    }

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const appointmentId = pathParts[pathParts.length - 2]
    const workflowStatus = new FormData(event.target).get("workflow_status")

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
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update operation appointment.") })
    }
  }
}

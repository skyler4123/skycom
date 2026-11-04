import { Controller } from "@hotwired/stimulus"

export default class Companies_Pages_AppointmentConfigModalController extends Controller {
  /** @type {any | null} */ appointment = null

  connect() {
    this.appointment = window.currentPageAppointment
    if (this.appointment) this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const appointment = this.appointment
    const metadata = JSON.stringify(appointment.metadata || {}, null, 2)
    const status = appointment.workflow_status || "active"
    const url = appointment.kind === "branch"
      ? Helpers.branch_page_appointment_path(currentCompany().id, appointment.id)
      : Helpers.page_warehouse_appointment_path(currentCompany().id, appointment.id)

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Appointment config")}</h2>
          <p class="text-sm text-muted-foreground">${appointment.page?.name || ""} · ${appointment.location?.name || ""}</p>
        </div>

        <div class="rounded-lg border border-line bg-muted/40 p-3 text-xs text-muted-foreground">
          ${translate("Page config overrides every appointment config.")}
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Metadata (JSON)")}</label>
          <textarea name="metadata" rows="8"
            class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none">${metadata}</textarea>
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
          <button type="button" data-action="click->${this.identifier}#close"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return form({
      action: url,
      method: "PATCH",
      attributes: `class="p-6 bg-card rounded-xl border border-line w-[520px] max-w-full" data-action="submit->${this.identifier}#handleSubmit"`,
      html: fields
    })
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

    const workflowStatus = new FormData(event.target).get("workflow_status")
    const kind = this.appointment.kind
    const url = kind === "branch"
      ? Helpers.branch_page_appointment_path(currentCompany().id, this.appointment.id)
      : Helpers.page_warehouse_appointment_path(currentCompany().id, this.appointment.id)
    const payload = kind === "branch"
      ? { branch_page_appointment: { metadata, workflow_status: workflowStatus } }
      : { page_warehouse_appointment: { metadata, workflow_status: workflowStatus } }

    try {
      const response = await fetchJson(url, { method: "PATCH", body: payload })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update page appointment.") })
    }
  }

  close(event) {
    event.preventDefault()
    closeModal()
  }
}

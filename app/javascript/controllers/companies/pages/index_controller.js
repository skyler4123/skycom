import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_IndexController extends Companies_LayoutController {
  /** @type {any[]} */ appointments = []
  /** @type {{ id: string, name: string }[]} */ roles = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.appointments = response.page_appointments || []
      this.roles = response.roles || []
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load page appointments")}${detail ? ": " + detail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col gap-5">
          <div class="flex flex-col gap-1">
            <h2 class="text-xl font-bold text-foreground">${translate("Page Appointments")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Appointments connect a page to a branch or warehouse. Page Configs override these values.")}</p>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-line">
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Page")}</th>
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
                  ? `<tr><td colspan="7" class="py-8 text-center text-muted-foreground">${translate("No page appointments found.")}</td></tr>`
                  : this.appointments.map(appointment => this.rowHTML(appointment)).join("")}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }

  rowHTML(appointment) {
    const page = appointment.page || {}
    const active = appointment.workflow_status === "active"
    const canLaunch = active && appointment.accessible
    const launchReason = !appointment.accessible
      ? translate("You do not have access to this page.")
      : translate("This page appointment is inactive.")
    const roles = Array.isArray(page.metadata?.roles) ? page.metadata.roles : []

    return `
      <tr class="border-b border-line hover:bg-muted/50">
        <td class="py-4 px-6">
          <p class="font-medium text-foreground">${Helpers.escapeHtml(page.name || translate("Unnamed Page"))}</p>
          <p class="font-mono text-xs text-muted-foreground">${Helpers.escapeHtml(page.code || "—")}</p>
        </td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml((page.page_type || "—").replace(/_/g, " ").toUpperCase())}</td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml(appointment.location?.name || "—")}</td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml(page.resolution || "—")}</td>
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
          <button type="button" data-action="click->${this.identifier}#openEditModal" data-${this.identifier}-appointment-id-param="${appointment.id}"
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer" ${tooltip(translate("Edit Config"))}>
            <span class="material-symbols-outlined text-[20px]">edit</span>
          </button>
        </td>
      </tr>
    `
  }

  openEditModal(event) {
    const appointment = this.appointments.find(a => a.id === event.params.appointmentId)
    if (!appointment) return

    window.currentPageAppointment = appointment
    openModal({ html: `<div data-controller="companies--pages--appointment-config-modal"></div>` })
  }
}

import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PageConfigs_IndexController extends Companies_LayoutController {
  /** @type {any[]} */ pageConfigs = []
  /** @type {{ id: string, name: string }[]} */ roles = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.pageConfigs = response.page_configs || []
      this.roles = response.roles || []
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load page configs")}${detail ? ": " + detail : ""}` })
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
            <h2 class="text-xl font-bold text-foreground">${translate("Page Configs")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Page config overrides every appointment config.")}</p>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-line">
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Page")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Type")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Resolution")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Access Roles")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Status")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Appointments")}</th>
                  <th class="text-right py-4 px-6 font-semibold text-foreground w-24">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.pageConfigs.length === 0
                  ? `<tr><td colspan="7" class="py-8 text-center text-muted-foreground">${translate("No page configs found.")}</td></tr>`
                  : this.pageConfigs.map(pageConfig => this.rowHTML(pageConfig)).join("")}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }

  rowHTML(pageConfig) {
    const roles = Array.isArray(pageConfig.metadata?.roles) ? pageConfig.metadata.roles : []
    const appointmentCount = (pageConfig.branch_appointment_count || 0) + (pageConfig.page_warehouse_appointment_count || 0)

    return `
      <tr class="border-b border-line hover:bg-muted/50">
        <td class="py-4 px-6">
          <p class="font-medium text-foreground">${pageConfig.name || translate("Unnamed Page")}</p>
          <p class="font-mono text-xs text-muted-foreground">${pageConfig.code || "—"}</p>
        </td>
        <td class="py-4 px-6 text-muted-foreground">${(pageConfig.page_type || "—").replace(/_/g, " ").toUpperCase()}</td>
        <td class="py-4 px-6 text-muted-foreground">${pageConfig.resolution || "—"}</td>
        <td class="py-4 px-6">
          ${roles.length === 0
            ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-line">${translate("All roles")}</span>`
            : roles.map(role => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary mr-1">${role}</span>`).join("")}
        </td>
        <td class="py-4 px-6">${Helpers.statusBadge(pageConfig.workflow_status)}</td>
        <td class="py-4 px-6 text-muted-foreground">${appointmentCount}</td>
        <td class="py-4 px-6 text-right whitespace-nowrap">
          <button type="button" data-action="click->${this.identifier}#openEditModal" data-${this.identifier}-page-config-id-param="${pageConfig.id}"
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer" ${tooltip(translate("Edit Config"))}>
            <span class="material-symbols-outlined text-[20px]">edit</span>
          </button>
        </td>
      </tr>
    `
  }

  openEditModal(event) {
    const pageConfig = this.pageConfigs.find(page => page.id === event.params.pageConfigId)
    if (!pageConfig) return

    window.currentPageConfig = pageConfig
    openModal({ html: `<div data-controller="companies--page-configs--edit-modal"></div>` })
  }
}

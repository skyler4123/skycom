import Companies_LayoutController from "controllers/companies/layout_controller"
import { DASHBOARD_BLOCKS } from "controllers/companies/dashboards/blocks"

// Dashboard Config — chooses which full-width blocks appear on the Dashboard.
// Depends on BE: Companies::DashboardsController#show|update
// Endpoints: GET/PATCH /companies/:company_id/dashboard.json
export default class Companies_Dashboards_ShowController extends Companies_LayoutController {
  /** @type {string[]} */ activeBlocks = []
  /** @type {string | null} */ error = null
  loaded = false

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      const dashboard = response.dashboard || {}
      this.activeBlocks = Array.isArray(dashboard.blocks) ? dashboard.blocks : []
    } catch (caught) {
      this.error = caught.errors?.join(", ") || caught.message || translate("Failed to load dashboard configuration")
      toast({ type: "error", message: this.error })
    }

    this.loaded = true
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  companyId() {
    return currentCompany()?.id || window.location.pathname.split("/")[2]
  }

  contentHTML() {
    if (!this.loaded) return this.loadingHTML()
    if (this.error) return this.errorHTML()

    const blockFields = DASHBOARD_BLOCKS.map((block) => `
      <label for="dashboard-block-${block.key}"
        class="flex items-start gap-3 p-4 rounded-xl border border-line bg-card hover:bg-muted/50 cursor-pointer">
        <input type="checkbox" id="dashboard-block-${block.key}"
          name="dashboard[blocks][]" value="${block.key}"
          ${this.activeBlocks.includes(block.key) ? "checked" : ""}
          class="mt-0.5 h-5 w-5 rounded border-line text-primary cursor-pointer">
        <span class="min-w-0">
          <span class="flex items-center gap-2 text-sm font-bold text-foreground">
            <span class="material-symbols-outlined text-[18px] text-muted-foreground">${block.icon}</span>
            ${translate(block.label)}
          </span>
          <span class="block text-xs text-muted-foreground mt-1">${translate(block.description)}</span>
        </span>
      </label>
    `).join("")

    const fields = `
      <div class="space-y-3">${blockFields}</div>
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pt-6 border-t border-line">
        <p class="text-xs text-muted-foreground">${translate("Blocks are stacked full-width on the dashboard. Unchecked blocks are hidden but keep their settings.")}</p>
        <div class="flex items-center gap-2">
          <a href="${Helpers.company_dashboards_path(this.companyId())}"
            class="px-4 py-2 rounded-lg bg-card border border-line text-foreground text-sm font-semibold hover:bg-muted">
            ${translate("Back to dashboard")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: `${Helpers.company_dashboard_path(this.companyId())}`,
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line space-y-6" data-action="submit->${this.identifier}#handleSubmit"`,
          html: `
            <div>
              <h2 class="text-xl font-bold text-foreground">${translate("Dashboard configuration")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Choose which blocks appear on your company dashboard.")}</p>
            </div>
            ${fields}
          `
        })}
      </div>
    `
  }

  async handleSubmit(event) {
    event.preventDefault()

    const formData = new FormData(event.target)
    const blocks = formData.getAll("dashboard[blocks][]")

    try {
      const response = await fetchJson(Helpers.company_dashboard_path(this.companyId()), {
        method: "PATCH",
        body: { dashboard: { blocks } }
      })
      this.activeBlocks = blocks
      toast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update dashboard configuration") })
    }
  }

  errorHTML() {
    return `
      <div class="p-6">
        <div class="bg-card border border-line rounded-xl p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-danger">error</span>
          <h2 class="text-lg font-bold text-foreground mt-2">${translate("Failed to load dashboard configuration")}</h2>
          <p class="text-sm text-muted-foreground mt-1">${Helpers.escapeHtml(this.error)}</p>
          <a href="${Helpers.company_dashboards_path(this.companyId())}"
            class="mt-4 inline-flex px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold">
            ${translate("Back to dashboard")}
          </a>
        </div>
      </div>
    `
  }

  loadingHTML() {
    return `
      <div class="p-4 space-y-4">
        <div class="h-20 rounded-xl bg-muted animate-pulse"></div>
        <div class="h-96 rounded-xl bg-muted animate-pulse"></div>
      </div>
    `
  }
}

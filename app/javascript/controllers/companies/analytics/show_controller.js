import Companies_LayoutController from "controllers/companies/layout_controller"
import { ANALYTICS_BLOCKS } from "controllers/companies/analytics/blocks"

// Analytics Config — chooses which full-width blocks appear on the Analytics page.
// Depends on BE: Companies::AnalyticsController#show|update
// Endpoints: GET/PATCH /companies/:company_id/analytic.json
export default class Companies_Analytics_ShowController extends Companies_LayoutController {
  /** @type {string[]} */ activeBlocks = []
  /** @type {string | null} */ error = null
  loaded = false

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      const analytic = response.analytic || {}
      this.activeBlocks = Array.isArray(analytic.blocks) ? analytic.blocks : []
    } catch (caught) {
      this.error = caught.errors?.join(", ") || caught.message || translate("Failed to load analytics configuration")
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

    const blockFields = ANALYTICS_BLOCKS.map((block) => `
      <label for="analytic-block-${block.key}"
        class="flex items-start gap-3 p-4 rounded-xl border border-line bg-card hover:bg-muted/50 cursor-pointer">
        <input type="checkbox" id="analytic-block-${block.key}"
          name="analytic[blocks][]" value="${block.key}"
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
        <p class="text-xs text-muted-foreground">${translate("Blocks are stacked full-width on the analytics page. Unchecked blocks are hidden but keep their settings.")}</p>
        <div class="flex items-center gap-2">
          <a href="${Helpers.company_analytics_path(this.companyId())}"
            class="px-4 py-2 rounded-lg bg-card border border-line text-foreground text-sm font-semibold hover:bg-muted">
            ${translate("Back to analytics")}
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
          action: `${Helpers.company_analytic_path(this.companyId())}`,
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line space-y-6" data-action="submit->${this.identifier}#handleSubmit"`,
          html: `
            <div>
              <h2 class="text-xl font-bold text-foreground">${translate("Analytics configuration")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Choose which blocks appear on your company analytics page.")}</p>
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
    const blocks = formData.getAll("analytic[blocks][]")

    try {
      const response = await fetchJson(Helpers.company_analytic_path(this.companyId()), {
        method: "PATCH",
        body: { analytic: { blocks } }
      })
      this.activeBlocks = blocks
      toast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update analytics configuration") })
    }
  }

  errorHTML() {
    return `
      <div class="p-6">
        <div class="bg-card border border-line rounded-xl p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-danger">error</span>
          <h2 class="text-lg font-bold text-foreground mt-2">${translate("Failed to load analytics configuration")}</h2>
          <p class="text-sm text-muted-foreground mt-1">${Helpers.escapeHtml(this.error)}</p>
          <a href="${Helpers.company_analytics_path(this.companyId())}"
            class="mt-4 inline-flex px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold">
            ${translate("Back to analytics")}
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

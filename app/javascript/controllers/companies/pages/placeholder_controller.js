import { Controller } from "@hotwired/stimulus"

// Shared shell for purpose-specific operation pages that are not built yet.
// Subclasses only declare their Stimulus identity; the backend still enforces
// the page type, appointment and role gate.
export default class Companies_Pages_PlaceholderController extends Controller {
  /** @type {any | null} */ page = null
  /** @type {any | null} */ appointment = null
  /** @type {any | null} */ config = null

  async connect() {
    try {
      const pathParts = window.location.pathname.split("/")
      const companyId = pathParts[2]
      const pageId = this.element.dataset.operationPageId
      const pageType = this.element.dataset.operationPageType
      const url = pageId && pageType
        ? `/companies/${companyId}/pages/${pageType}/${pageId}.json${window.location.search}`
        : `${window.location.pathname}.json${window.location.search}`
      const response = await fetchJson(url)
      this.page = response.page
      this.appointment = response.appointment
      this.config = response.config
      this.element.innerHTML = this.contentHTML()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load page.")}${detail ? ": " + detail : ""}</div>`
    }
  }

  contentHTML() {
    const page = this.page || {}
    const appointment = this.appointment || {}

    return `
      <div class="min-h-screen bg-background p-6 flex items-center justify-center">
        <div class="w-full max-w-2xl rounded-xl border border-line bg-card p-8 flex flex-col gap-6">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-xs font-bold uppercase text-muted-foreground">${(page.page_type || "").replace(/_/g, " ")}</p>
              <h1 class="text-2xl font-bold text-foreground">${page.name || translate("Operating Page")}</h1>
              <p class="text-sm text-muted-foreground">${appointment.location?.name || ""}</p>
            </div>
            <span class="rounded-full bg-warning/10 px-3 py-1 text-xs font-semibold text-warning">${translate("Coming soon")}</span>
          </div>

          <div class="rounded-lg border border-line bg-background p-4 text-sm text-muted-foreground">
            ${translate("This operating page is scaffolded. The page type, appointment, access roles and config are already wired.")}
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div class="rounded-lg border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Resolution")}</p>
              <p class="text-sm font-semibold text-foreground">${page.resolution || "—"}</p>
            </div>
            <div class="rounded-lg border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Status")}</p>
              <p class="text-sm font-semibold text-foreground">${appointment.workflow_status || "—"}</p>
            </div>
          </div>

          <a href="${Helpers.company_pages_path(window.location.pathname.split("/")[2])}"
            class="inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Page Appointments")}
          </a>
        </div>
      </div>
    `
  }
}

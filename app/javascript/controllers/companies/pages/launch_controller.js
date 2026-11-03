import { Controller } from "@hotwired/stimulus"

export default class Companies_Pages_LaunchController extends Controller {
  // Depends on BE: Companies::PagesController#launch (placeholder payload)
  // Endpoints: Helpers.launch_company_page_path, Helpers.company_pages_path
  // Docs: docs/OPERATING_PAGES.md
  /** @type {any | null} */ page = null

  async connect() {
    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const pageId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.launch_company_page_path(companyId, pageId)}.json`)
      this.page = response.page
      this.element.innerHTML = this.contentHTML()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `
        <div class="flex h-screen items-center justify-center p-6">
          <div class="max-w-md rounded-xl border border-line bg-card p-6 text-center">
            <p class="text-sm font-semibold text-danger">${translate("Failed to load page.")}</p>
            <p class="mt-2 text-xs text-muted-foreground">${detail || ""}</p>
            <a href="${Helpers.company_pages_path(companyId)}" class="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-primary">
              <span class="material-symbols-outlined text-[18px]">arrow_back</span>
              ${translate("Back to Pages")}
            </a>
          </div>
        </div>
      `
    }
  }

  contentHTML() {
    const page = this.page
    if (!page) return ""

    const companyId = window.location.pathname.split("/")[2]

    return `
      <div class="flex min-h-screen items-center justify-center bg-background p-6">
        <div class="w-full max-w-2xl rounded-2xl border border-line bg-card p-8 shadow-sm">
          <a href="${Helpers.company_pages_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm font-medium text-muted-foreground hover:text-foreground">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Pages")}
          </a>

          <div class="mt-8 flex flex-col items-center text-center">
            <div class="flex size-20 items-center justify-center rounded-2xl bg-primary/10 text-primary">
              <span class="material-symbols-outlined text-4xl">construction</span>
            </div>
            <p class="mt-6 text-xs font-bold uppercase tracking-wider text-primary">${translate("Coming soon")}</p>
            <h1 class="mt-2 text-2xl font-black text-foreground">${page.name}</h1>
            <p class="mt-2 max-w-md text-sm text-muted-foreground">${translate("We are building this page. It will be available here soon.")}</p>
          </div>

          <div class="mt-8 grid grid-cols-1 gap-3 border-t border-line pt-6 sm:grid-cols-3">
            ${this.detail("Branch", page.branch?.name || "—")}
            ${this.detail("Target Role", this.humanize(page.target_role))}
            ${this.detail("Target Resolution", this.humanize(page.target_resolution))}
          </div>
        </div>
      </div>
    `
  }

  detail(label, value) {
    return `
      <div class="rounded-lg border border-line bg-background p-3">
        <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate(label)}</p>
        <p class="mt-1 truncate text-sm font-semibold text-foreground">${value}</p>
      </div>
    `
  }

  humanize(value) {
    return (value || "—").replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())
  }
}

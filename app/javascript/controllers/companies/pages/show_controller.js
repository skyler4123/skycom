import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_ShowController extends Companies_LayoutController {
  /** @type {any | null} */ page = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_page_path(companyId, recordId)}.json`)
      this.page = response.page

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load page.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  showHTML() {
    const p = this.page
    if (!p) return `<div class="p-8 text-center">${translate("Page not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const manifestStr = p.metadata?.layout_manifest
      ? (typeof p.metadata?.layout_manifest === 'object' ? JSON.stringify(p.metadata?.layout_manifest, null, 2) : p.metadata?.layout_manifest)
      : null

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_pages_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Pages")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-primary/20 /30 bg-primary/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">description</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${p.name}</h2>
              <p class="font-semibold text-primary">${p.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-primary/10 /40 px-3 py-1 text-xs font-bold text-primary uppercase">${p.code || translate("N/A")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">store</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Branch")}</p>
                <p class="text-sm font-semibold text-foreground">${p.branch?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Business Type")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(p.business_type?.replace('_', ' ') || 'retail')}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">assignment_ind</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Target Role")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(p.target_role?.replace(/_/g, ' ') || translate("N/A"))}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">devices</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Target Resolution")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(p.target_resolution?.replace(/_/g, ' ') || translate("N/A"))}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(p.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
                <span class="material-symbols-outlined">refresh</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Lifecycle")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(p.lifecycle_status?.replace(/_/g, ' ') || translate("N/A"))}</p>
              </div>
            </div>
          </div>

          ${manifestStr ? `
            <div class="border-t border-line pt-6 mt-6">
              <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Layout Manifest")}</h3>
              <pre class="bg-background rounded-lg p-4 text-xs font-mono text-foreground overflow-x-auto">${manifestStr}</pre>
            </div>
          ` : ''}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_page_path(companyId, p.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Page")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}

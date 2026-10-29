import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Workflows_ShowController extends Companies_LayoutController {
  // Workflow detail — template info + ordered step list.
  // Depends on BE: Companies::WorkflowsController#show
  // Endpoints: GET company_workflow_path.json
  // Docs: docs/PURCHASE_WORKFLOW.md
  /** @type {any | null} */
  workflow = null

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_workflow_path(companyId, recordId)}.json`)
      this.workflow = response.workflow

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load workflow.")}</div>`
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
    const w = this.workflow
    if (!w) return `<div class="p-8 text-center">${translate("Workflow not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_workflows_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Workflows")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-primary/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">account_tree</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${w.name}</h2>
              <p class="font-semibold text-primary">${w.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-primary/10 /40 px-3 py-1 text-xs font-bold text-primary uppercase">${w.code || "N/A"}</span>
                <span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-muted-foreground capitalize">${w.process_type?.replace(/_/g, ' ') || "N/A"}</span>
                ${Helpers.statusBadge(w.workflow_status)}
              </div>
            </div>
          </div>

          <div class="border-t border-line pt-6">
            <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Category")}</h3>
            <p class="text-sm font-semibold text-foreground">${w.category?.name || "N/A"}</p>
          </div>

          <div class="border-t border-line pt-6 mt-6">
            <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Steps")}</h3>
            <div>
              ${(w.steps || []).map(s => `
                <div class="flex items-center gap-3 py-2 border-b border-line">
                   <span class="flex size-8 items-center justify-center rounded-lg ${s.background_color || 'bg-primary/10'} ${s.text_color || 'text-primary'} text-sm font-bold cursor-default">${s.position}</span>
                   <span class="inline-flex items-center px-2.5 py-1 rounded-md text-sm font-semibold ${s.text_color || 'text-foreground'} ${s.background_color || ''}">${s.name}</span>
                </div>`).join('')}
            </div>
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_workflow_path(companyId, w.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Workflow")}
            </a>
          </div>
        </div>
      </div>`
  }
}

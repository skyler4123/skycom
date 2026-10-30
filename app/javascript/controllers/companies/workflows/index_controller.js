import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Workflows_IndexController extends Companies_LayoutController {
  // Workflows dashboard — static table of generic process templates.
  // Depends on BE: Companies::WorkflowsController#index (list)
  // Endpoints: GET company_workflows_path.json
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["workflowsList"]

  /** @type {Array<{id: string, name: string, code: string, process_type: string, category: {id: string, name: string}, steps: any[]}>} */
  workflows = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.workflows = response.workflows || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load workflows") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Workflows")}</h2>
            <a href="${Helpers.new_company_workflow_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Code")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Process")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Category")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Steps")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="workflowsList" class="divide-y divide-line">
                ${this.workflows.map(w => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_workflow_path(currentCompany().id, w.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${w.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${w.code || '—'}</span>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground capitalize">${w.process_type?.replace(/_/g, ' ') || '—'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${w.category?.name || '<span class="text-muted-foreground/60">—</span>'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${(w.steps || []).length}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_workflow_path(currentCompany().id, w.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}

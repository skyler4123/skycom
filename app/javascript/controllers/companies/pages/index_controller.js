import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Pages_IndexController extends Companies_LayoutController {
  static targets = ["branchSelect", "pagesList"]

  /** @type {any[]} */ pages = []
  /** @type {string | null} */ branchIdValue = null

  async connect() {
    super.connect()

    this.branchIdValue = new URLSearchParams(window.location.search).get("branch_id")

    try {
      const response = await fetchJson({ params: { branch_id: this.branchIdValue || undefined } })
      this.pages = response.pages || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load pages") }${__errDetail ? ": " + __errDetail : ""}` })
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
    const branches = currentBranches()

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Branch")}</label>
              <select
                data-${this.identifier}-target="branchSelect"
                data-action="change->${this.identifier}#onBranchChange"
                class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
              >
                <option value="">${translate("All Branches")}</option>
                ${branches.map(b =>
                  `<option value="${b.id}" ${b.id === this.branchIdValue ? "selected" : ""}>${b.name}</option>`
                ).join("")}
              </select>
            </div>
            <a href="${Helpers.new_company_page_path(currentCompany().id)}"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-line">
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Name")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Launch")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Code")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Branch")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Target Role")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Resolution")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Status")}</th>
                  <th class="text-right py-4 px-6 font-semibold text-foreground w-20">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="pagesList">
                ${this.pages.length === 0
                  ? `<tr><td colspan="8" class="py-8 text-center text-muted-foreground">${translate("No pages found.")}</td></tr>`
                  : this.pages.map(p => `
                    <tr class="border-b border-line hover:bg-muted/50">
                      <td class="py-4 px-6">
                        <a href="${Helpers.company_page_path(currentCompany().id, p.id)}"
                          class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                          ${p.name || translate("Unnamed Page")}
                        </a>
                      </td>
                      <td class="py-4 px-6 whitespace-nowrap">
                        <a href="${Helpers.retail_cashier_company_page_path(currentCompany().id, p.id)}"
                          class="inline-flex items-center justify-center p-2 text-success hover:text-success hover:bg-success/10 rounded-lg cursor-pointer"
                          title="${translate("Launch Cashier")}">
                          <span class="material-symbols-outlined text-[20px]">open_in_new</span>
                        </a>
                      </td>
                      <td class="py-4 px-6">
                        <span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${p.code || "—"}</span>
                      </td>
                      <td class="py-4 px-6 text-muted-foreground">${p.branch?.name || "—"}</td>
                      <td class="py-4 px-6">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary ">
                          ${p.target_role?.replace(/_/g, " ") || "—"}
                        </span>
                      </td>
                      <td class="py-4 px-6 text-xs text-muted-foreground">${p.target_resolution?.replace(/_/g, " ") || "—"}</td>
                      <td class="py-4 px-6">${Helpers.statusBadge(p.workflow_status)}</td>
                      <td class="py-4 px-6 text-right whitespace-nowrap">
                        <a href="${Helpers.edit_company_page_path(currentCompany().id, p.id)}"
                          class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                          <span class="material-symbols-outlined text-[20px]">edit</span>
                        </a>
                      </td>
                    </tr>
                  `).join("")}
              </tbody>
            </table>
          </div>

        </div>
      </div>
    `
  }

  onBranchChange(event) {
    this.branchIdValue = event.target.value || null
    this.pages = []
    fetchJson({ params: { branch_id: this.branchIdValue || undefined } })
      .then(response => {
        this.pages = response.pages || []
        this.renderContent()
      })
  }
}

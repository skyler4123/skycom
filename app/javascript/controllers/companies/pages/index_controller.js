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
      toast({ type: "error", message: "Failed to load pages" })
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
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Branch</label>
              <select
                data-${this.identifier}-target="branchSelect"
                data-action="change->${this.identifier}#onBranchChange"
                class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
              >
                <option value="">All Branches</option>
                ${branches.map(b =>
                  `<option value="${b.id}" ${b.id === this.branchIdValue ? "selected" : ""}>${b.name}</option>`
                ).join("")}
              </select>
            </div>
            <a href="${Helpers.new_company_page_path(currentCompany().id)}"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add
            </a>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-slate-200 dark:border-slate-700">
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Name</th>
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Code</th>
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Branch</th>
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Target Role</th>
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Resolution</th>
                  <th class="text-left py-4 px-6 font-semibold text-slate-900 dark:text-white">Status</th>
                  <th class="text-right py-4 px-6 font-semibold text-slate-900 dark:text-white w-20">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="pagesList">
                ${this.pages.length === 0
                  ? `<tr><td colspan="7" class="py-8 text-center text-slate-400">No pages found.</td></tr>`
                  : this.pages.map(p => `
                    <tr class="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                      <td class="py-4 px-6">
                        <a href="${Helpers.company_page_path(currentCompany().id, p.id)}"
                          class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                          ${p.name || "Unnamed Page"}
                        </a>
                      </td>
                      <td class="py-4 px-6">
                        <span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${p.code || "—"}</span>
                      </td>
                      <td class="py-4 px-6 text-slate-600 dark:text-slate-300">${p.branch?.name || "—"}</td>
                      <td class="py-4 px-6">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
                          ${p.target_role?.replace(/_/g, " ") || "—"}
                        </span>
                      </td>
                      <td class="py-4 px-6 text-xs text-slate-500 dark:text-slate-400">${p.target_resolution?.replace(/_/g, " ") || "—"}</td>
                      <td class="py-4 px-6">${Helpers.statusBadge(p.workflow_status)}</td>
                      <td class="py-4 px-6 text-right whitespace-nowrap">
                        <a href="${Helpers.retail_cashier_company_page_path(currentCompany().id, p.id)}"
                          class="inline-flex items-center justify-center p-2 text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 dark:hover:bg-slate-800 rounded-lg cursor-pointer"
                          title="Launch Cashier">
                          <span class="material-symbols-outlined text-[20px]">open_in_new</span>
                        </a>
                        <a href="${Helpers.edit_company_page_path(currentCompany().id, p.id)}"
                          class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
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

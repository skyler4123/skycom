import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Exams_IndexController extends Companies_LayoutController {
  // Exams index.
  // Depends on BE: Companies::ExamsController#index
  // Endpoints: GET /companies/:id/exams.json?q&workflow_status
  // Docs: docs/EXAMS.md

  /** @type {Exam[]} */
  exams = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exams = response.exams || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load exams")}${detail ? ": " + detail : ""}` })
    }
  }

  statusLabel(status) {
    const entry = (ENUMS?.exam?.workflow_statuses || []).find(item => item.value === status)
    return entry ? translate(entry.name) : status
  }

  statusClasses(status) {
    switch (status) {
      case "published": return "bg-success/10 text-success"
      case "archived": return "bg-warning/10 text-warning"
      default: return "bg-muted text-muted-foreground"
    }
  }

  passRateText(summary) {
    if (summary?.pass_rate === null || summary?.pass_rate === undefined) return "—"
    return `${Number(summary.pass_rate).toFixed(2)}%`
  }

  contentHTML() {
    const companyId = currentCompany()?.id
    const urlParams = new URLSearchParams(window.location.search)
    const statusValue = urlParams.get("workflow_status") || ""
    const statuses = (ENUMS?.exam?.workflow_statuses || []).map(status => ({ value: status.value, name: translate(status.name) }))

    return `
      <div class="p-4 overflow-y-auto">
        <div class="rounded-xl border border-line bg-card p-4">
          <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <form method="get" action="${pathname()}" class="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Search")}</label>
                <input type="search" name="q" value="${escapeHtml(urlParams.get("q") || "")}"
                  placeholder="${translate("Search exams...")}"
                  class="h-[38px] rounded-lg border border-line bg-card px-3 text-sm text-foreground placeholder:text-muted-foreground">
              </div>
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Status")}</label>
                <select name="workflow_status" class="h-[38px] rounded-lg border border-line bg-card px-3 text-sm text-foreground">
                  ${selectOptionsHTML(statuses, statusValue, translate("All Statuses"))}
                </select>
              </div>
              <button type="submit"
                class="flex h-[38px] items-center gap-2 rounded-lg bg-primary px-5 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                <span class="material-symbols-outlined text-[18px]!">search</span>${translate("Search")}
              </button>
            </form>

            <a href="${Helpers.new_company_exam_path(companyId)}"
              class="flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
              <span class="material-symbols-outlined text-[20px]">add</span>${translate("Add Exam")}
            </a>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-left">
              <thead>
                <tr class="border-b border-line bg-muted text-sm text-muted-foreground">
                  <th class="px-4 py-3 font-medium">${translate("Exam")}</th>
                  <th class="px-4 py-3 font-medium">${translate("Status")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Duration")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Questions")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Assigned")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Pass Rate")}</th>
                  <th class="px-4 py-3 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.exams.map(exam => `
                  <tr class="border-b border-line/70 hover:bg-muted/50">
                    <td class="px-4 py-3">
                      <a href="${Helpers.company_exam_path(companyId, exam.id)}"
                        class="font-medium text-foreground hover:text-primary">${escapeHtml(exam.name)}</a>
                      <p class="max-w-md truncate text-xs text-muted-foreground">${escapeHtml(exam.description || "")}</p>
                    </td>
                    <td class="px-4 py-3">
                      <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses(exam.workflow_status)}">
                        ${this.statusLabel(exam.workflow_status)}
                      </span>
                    </td>
                    <td class="px-4 py-3 text-center text-sm text-muted-foreground">
                      ${exam.duration_minutes ? `${exam.duration_minutes} ${translate("min")}` : "—"}
                    </td>
                    <td class="px-4 py-3 text-center text-sm text-foreground">${exam.questions_count || 0}</td>
                    <td class="px-4 py-3 text-center text-sm text-foreground">${exam.assigned_count || 0}</td>
                    <td class="px-4 py-3 text-center text-sm text-foreground">${this.passRateText(exam.summary)}</td>
                    <td class="px-4 py-3 text-right">
                      <a href="${Helpers.edit_company_exam_path(companyId, exam.id)}"
                        class="inline-flex items-center justify-center rounded-lg p-2 text-muted-foreground hover:bg-primary/10 hover:text-primary">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>

          ${this.exams.length === 0 ? `
            <div class="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <span class="material-symbols-outlined mb-2 text-4xl">quiz</span>
              <p>${translate("No exams found")}</p>
            </div>
          ` : ""}

          <div class="flex justify-center pt-6">${pagination(this.pagination)}</div>
        </div>
      </div>
    `
  }
}

import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ExamAppointments_IndexController extends Companies_LayoutController {
  // Manager attempt list for one exam.
  // Depends on BE: Companies::ExamAppointmentsController#index
  // Endpoints: GET /companies/:id/exams/:exam_id/appointments.json?q&workflow_status
  // Docs: docs/EXAMS.md

  exam = null
  appointments = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exam = response.exam
      this.appointments = response.appointments || []
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
      toast({ type: "error", message: `${translate("Failed to load attempts")}${detail ? ": " + detail : ""}` })
    }
  }

  statusLabel(appointment) {
    if (appointment.status === "graded") return appointment.passed ? translate("Passed") : translate("Failed")
    const entry = (ENUMS?.employee_exam_appointment?.workflow_statuses || []).find(item => item.value === appointment.status)
    return entry ? translate(entry.name) : appointment.status
  }

  statusClasses(appointment) {
    if (appointment.status === "graded") {
      return appointment.passed ? "bg-success/10 text-success" : "bg-danger/10 text-danger"
    }
    switch (appointment.status) {
      case "in_progress": return "bg-warning/10 text-warning"
      case "submitted": return "bg-primary/10 text-primary"
      case "expired": return "bg-warning/10 text-warning"
      default: return "bg-muted text-muted-foreground"
    }
  }

  contentHTML() {
    const companyId = currentCompany()?.id
    const exam = this.exam
    if (!exam) return `<div class="p-8 text-center text-muted-foreground">${translate("Exam not found.")}</div>`

    const urlParams = new URLSearchParams(window.location.search)
    const statusValue = urlParams.get("workflow_status") || ""
    const statuses = (ENUMS?.employee_exam_appointment?.workflow_statuses || []).map(status => ({ value: status.value, name: translate(status.name) }))

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-5xl space-y-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <a href="${Helpers.company_exam_path(companyId, exam.id)}"
                class="mb-1 inline-flex items-center gap-1 text-xs font-medium text-muted-foreground hover:text-primary">
                <span class="material-symbols-outlined text-[16px]!">arrow_back</span>${escapeHtml(exam.name)}
              </a>
              <h2 class="text-xl font-bold text-foreground">${translate("Attempts")}</h2>
            </div>
          </div>

          <div class="rounded-xl border border-line bg-card p-4">
            <form method="get" action="${pathname()}" class="mb-4 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Search")}</label>
                <input type="search" name="q" value="${escapeHtml(urlParams.get("q") || "")}"
                  placeholder="${translate("Search employees...")}"
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

            <div class="overflow-x-auto">
              <table class="w-full border-collapse text-left">
                <thead>
                  <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
                    <th class="px-4 py-3 font-medium">${translate("Employee")}</th>
                    <th class="px-4 py-3 text-center font-medium">${translate("Attempt")}</th>
                    <th class="px-4 py-3 text-center font-medium">${translate("Status")}</th>
                    <th class="px-4 py-3 text-center font-medium">${translate("Score")}</th>
                    <th class="px-4 py-3 text-center font-medium">${translate("Submitted")}</th>
                    <th class="px-4 py-3 text-right font-medium">${translate("Actions")}</th>
                  </tr>
                </thead>
                <tbody>
                  ${this.appointments.map(appointment => `
                    <tr class="border-b border-line/70 hover:bg-muted/40">
                      <td class="px-4 py-3 text-sm text-foreground">${escapeHtml(appointment.employee?.name || "—")}</td>
                      <td class="px-4 py-3 text-center text-sm text-muted-foreground">#${appointment.attempt_number}</td>
                      <td class="px-4 py-3 text-center">
                        <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses(appointment)}">
                          ${this.statusLabel(appointment)}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-center text-sm text-foreground">${appointment.score === null || appointment.score === undefined ? "—" : Number(appointment.score).toFixed(2)}</td>
                      <td class="px-4 py-3 text-center text-xs text-muted-foreground">${appointment.submitted_at ? Helpers.timeFormat(appointment.submitted_at) : "—"}</td>
                      <td class="px-4 py-3 text-right">
                        <a href="${Helpers.company_exam_appointment_path(companyId, exam.id, appointment.id)}"
                          class="inline-flex items-center justify-center rounded-lg p-2 text-muted-foreground hover:bg-primary/10 hover:text-primary">
                          <span class="material-symbols-outlined text-[20px]">visibility</span>
                        </a>
                      </td>
                    </tr>
                  `).join("")}
                </tbody>
              </table>
            </div>

            ${this.appointments.length === 0 ? `
              <div class="flex flex-col items-center justify-center py-12 text-muted-foreground">
                <span class="material-symbols-outlined mb-2 text-4xl">quiz</span>
                <p>${translate("No attempts found")}</p>
              </div>
            ` : ""}

            <div class="flex justify-center pt-6">${pagination(this.pagination)}</div>
          </div>
        </div>
      </div>
    `
  }
}

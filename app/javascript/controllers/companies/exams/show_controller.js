import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Exams_ShowController extends Companies_LayoutController {
  // Exam detail + summary card.
  // Depends on BE: Companies::ExamsController#show/#publish/#archive/#refresh_summary/#destroy
  // Endpoints: GET /companies/:id/exams/:id.json,
  //            POST /companies/:id/exams/:id/publish|archive|refresh_summary,
  //            DELETE /companies/:id/exams/:id
  // Docs: docs/EXAMS.md

  /** @type {Exam | null} */
  exam = null
  /** @type {Question[]} */
  questions = []
  /** @type {ExamSummary | null} */
  summary = null
  /** @type {Array} */
  recentAppointments = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exam = response.exam
      this.questions = response.questions || []
      this.summary = response.summary
      this.recentAppointments = response.recent_appointments || []

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load exam")}${detail ? ": " + detail : ""}` })
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

  attemptStatusLabel(appointment) {
    if (appointment.workflow_status === "graded") {
      return appointment.passed ? translate("Passed") : translate("Failed")
    }
    const entry = (ENUMS?.employee_exam_appointment?.workflow_statuses || []).find(item => item.value === appointment.workflow_status)
    return entry ? translate(entry.name) : appointment.workflow_status
  }

  attemptStatusClasses(appointment) {
    if (appointment.workflow_status === "graded") {
      return appointment.passed ? "bg-success/10 text-success" : "bg-danger/10 text-danger"
    }
    switch (appointment.workflow_status) {
      case "in_progress": return "bg-warning/10 text-warning"
      case "submitted": return "bg-primary/10 text-primary"
      case "expired": return "bg-warning/10 text-warning"
      case "cancelled": return "bg-muted text-muted-foreground"
      default: return "bg-muted text-muted-foreground"
    }
  }

  summaryValue(value, suffix = "") {
    if (value === null || value === undefined || value === "") return "—"
    return `${value}${suffix}`
  }

  summaryHTML() {
    const summary = this.summary || {}
    const cards = [
      { label: translate("Assigned"), value: summary.assigned_count || 0 },
      { label: translate("Started"), value: summary.started_count || 0 },
      { label: translate("Submitted"), value: summary.submitted_count || 0 },
      { label: translate("Graded"), value: summary.graded_count || 0 },
      { label: translate("Passed"), value: summary.passed_count || 0, tone: "text-success" },
      { label: translate("Failed"), value: summary.failed_count || 0, tone: "text-danger" },
      { label: translate("Pending Review"), value: summary.pending_review_count || 0, tone: "text-warning" },
      { label: translate("Expired"), value: summary.expired_count || 0, tone: "text-warning" },
      { label: translate("Pass Rate"), value: this.summaryValue(summary.pass_rate === null || summary.pass_rate === undefined ? null : Number(summary.pass_rate).toFixed(2), "%") },
      { label: translate("Average Score"), value: this.summaryValue(summary.average_score === null || summary.average_score === undefined ? null : Number(summary.average_score).toFixed(2)) },
      { label: translate("Highest Score"), value: this.summaryValue(summary.highest_score === null || summary.highest_score === undefined ? null : Number(summary.highest_score).toFixed(2)) },
      { label: translate("Lowest Score"), value: this.summaryValue(summary.lowest_score === null || summary.lowest_score === undefined ? null : Number(summary.lowest_score).toFixed(2)) }
    ]

    return `
      <div class="rounded-xl border border-line bg-card p-4">
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Exam Summary")}</h3>
            <p class="text-xs text-muted-foreground">
              ${summary.computed_at ? `${translate("Last computed")}: ${Helpers.timeFormat(summary.computed_at)}` : translate("Not computed yet")}
            </p>
          </div>
          <button type="button" data-action="click->${this.identifier}#refreshSummary"
            class="inline-flex items-center gap-1.5 rounded-lg bg-muted px-3 py-2 text-xs font-bold text-foreground hover:bg-primary/10 hover:text-primary">
            <span class="material-symbols-outlined text-[16px]!">refresh</span>${translate("Refresh Summary")}
          </button>
        </div>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          ${cards.map(card => `
            <div class="rounded-lg border border-line bg-background p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${card.label}</p>
              <p class="mt-1 text-lg font-bold ${card.tone || "text-foreground"}">${card.value}</p>
            </div>
          `).join("")}
        </div>
      </div>
    `
  }

  questionsHTML() {
    if (this.questions.length === 0) {
      return `<p class="p-4 text-sm text-muted-foreground">${translate("No questions in this exam yet.")}</p>`
    }

    return this.questions.map((question, index) => `
      <div class="flex items-center gap-3 border-b border-line/70 px-4 py-3 last:border-b-0">
        <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-bold text-foreground">${index + 1}</span>
        <div class="min-w-0 flex-1">
          <p class="truncate text-sm font-medium text-foreground">${escapeHtml(question.name)}</p>
          <p class="text-xs text-muted-foreground">${escapeHtml(question.category?.name || "—")} · ${question.points} ${translate("points")}</p>
        </div>
      </div>
    `).join("")
  }

  appointmentsHTML() {
    if (this.recentAppointments.length === 0) {
      return `<p class="p-4 text-sm text-muted-foreground">${translate("No attempts yet.")}</p>`
    }

    return `
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-left">
          <thead>
            <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
              <th class="px-4 py-3 font-medium">${translate("Employee")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Attempt")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Status")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Score")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Submitted")}</th>
            </tr>
          </thead>
          <tbody>
            ${this.recentAppointments.map(appointment => `
              <tr class="border-b border-line/70">
                <td class="px-4 py-3 text-sm text-foreground">${escapeHtml(appointment.employee?.name || "—")}</td>
                <td class="px-4 py-3 text-center text-sm text-muted-foreground">#${appointment.attempt_number}</td>
                <td class="px-4 py-3 text-center">
                  <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.attemptStatusClasses(appointment)}">
                    ${this.attemptStatusLabel(appointment)}
                  </span>
                </td>
                <td class="px-4 py-3 text-center text-sm text-foreground">${appointment.score === null || appointment.score === undefined ? "—" : Number(appointment.score).toFixed(2)}</td>
                <td class="px-4 py-3 text-center text-xs text-muted-foreground">${appointment.submitted_at ? Helpers.timeFormat(appointment.submitted_at) : "—"}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  contentHTML() {
    const exam = this.exam
    if (!exam) return `<div class="p-8 text-center text-muted-foreground">${translate("Exam not found.")}</div>`

    const companyId = currentCompany()?.id
    const isDraft = exam.workflow_status === "draft"
    const isPublished = exam.workflow_status === "published"

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-6xl space-y-4">
          <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <div class="mb-2 flex flex-wrap items-center gap-2">
                <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses(exam.workflow_status)}">${this.statusLabel(exam.workflow_status)}</span>
                <span class="text-xs text-muted-foreground">${exam.questions_count} ${translate("questions")}</span>
                <span class="text-xs text-muted-foreground">${exam.duration_minutes ? `${exam.duration_minutes} ${translate("min")}` : translate("No time limit")}</span>
                <span class="text-xs text-muted-foreground">${translate("Pass mark")}: ${Number(exam.passing_score).toFixed(2)}%</span>
              </div>
              <h2 class="text-xl font-bold text-foreground">${escapeHtml(exam.name)}</h2>
              <p class="mt-1 max-w-3xl text-sm text-muted-foreground">${escapeHtml(exam.description || "")}</p>
            </div>

            <div class="flex flex-wrap items-center gap-2">
              <a href="${Helpers.company_exams_path(companyId)}"
                class="rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted">${translate("Back")}</a>
              <a href="${Helpers.edit_company_exam_path(companyId, exam.id)}"
                class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                <span class="material-symbols-outlined text-[18px]!">edit</span>${translate("Edit")}
              </a>
              ${isDraft ? `
                <button type="button" data-action="click->${this.identifier}#publishExam"
                  class="inline-flex items-center gap-1.5 rounded-lg bg-success px-3 py-2 text-sm font-medium text-primary-foreground hover:bg-success/90">
                  <span class="material-symbols-outlined text-[18px]!">publish</span>${translate("Publish")}
                </button>
              ` : ""}
              ${isPublished ? `
                <button type="button" data-action="click->${this.identifier}#archiveExam"
                  class="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-sm font-medium text-warning hover:bg-warning/10">
                  <span class="material-symbols-outlined text-[18px]!">archive</span>${translate("Archive")}
                </button>
              ` : ""}
              <button type="button" data-action="click->${this.identifier}#deleteExam"
                class="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-sm font-medium text-danger hover:bg-danger/10">
                <span class="material-symbols-outlined text-[18px]!">delete</span>${translate("Delete")}
              </button>
            </div>
          </div>

          ${isDraft ? `
            <div class="rounded-lg border border-warning/40 bg-warning/10 p-3 text-sm text-warning">
              ${translate("This exam is a draft. Publish it before assigning employees.")}
            </div>
          ` : ""}

          ${this.summaryHTML()}

          <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <div class="rounded-xl border border-line bg-card">
              <div class="border-b border-line px-4 py-3">
                <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Questions")}</h3>
              </div>
              ${this.questionsHTML()}
            </div>

            <div class="rounded-xl border border-line bg-card">
              <div class="flex items-center justify-between border-b border-line px-4 py-3">
                <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Recent Attempts")}</h3>
                <a href="${Helpers.company_exam_appointments_path(companyId, exam.id)}"
                  class="text-xs font-medium text-primary hover:underline">${translate("View all")}</a>
              </div>
              ${this.appointmentsHTML()}
            </div>
          </div>
        </div>
      </div>
    `
  }

  async publishExam() {
    try {
      const response = await fetchJson(Helpers.publish_company_exam_path(currentCompany()?.id, this.exam.id), { method: "POST" })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  async archiveExam() {
    const result = await Helpers.confirmAction({
      title: translate("Archive this exam?"),
      text: translate("Employees will no longer be able to start it."),
      confirmButtonText: translate("Archive"),
      cancelButtonText: translate("Cancel")
    })
    if (!result.isConfirmed) return

    try {
      const response = await fetchJson(Helpers.archive_company_exam_path(currentCompany()?.id, this.exam.id), { method: "POST" })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  async deleteExam() {
    const result = await Helpers.confirmAction({
      title: translate("Delete this exam?"),
      text: translate("This cannot be undone."),
      confirmButtonText: translate("Delete"),
      cancelButtonText: translate("Cancel")
    })
    if (!result.isConfirmed) return

    try {
      const response = await fetchJson(Helpers.company_exam_path(currentCompany()?.id, this.exam.id), { method: "DELETE" })
      navigateThenToast(Helpers.company_exams_path(currentCompany()?.id), { type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  async refreshSummary() {
    try {
      const response = await fetchJson(Helpers.refresh_summary_company_exam_path(currentCompany()?.id, this.exam.id), { method: "POST" })
      toast({ type: "success", message: response.message })
      setTimeout(() => window.location.reload(), 1500)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }
}

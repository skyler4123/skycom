import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_MyExams_ShowController extends Companies_LayoutController {
  // Employee exam detail + attempt history.
  // Depends on BE: Companies::MyExamsController#show + #start
  // Endpoints: GET /companies/:id/my_exams/:id.json,
  //            POST /companies/:id/my_exams/:id/start
  // Docs: docs/EXAMS.md

  /** @type {Object | null} */
  exam = null
  attempts = []
  canStart = false
  attemptsUsed = 0
  maxAttempts = null
  inProgressAppointmentId = null

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exam = response.exam
      this.attempts = response.attempts || []
      this.canStart = response.can_start
      this.attemptsUsed = response.attempts_used || 0
      this.maxAttempts = response.max_attempts
      this.inProgressAppointmentId = response.in_progress_appointment_id

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

  attemptStatusLabel(attempt) {
    if (attempt.workflow_status === "graded") return attempt.passed ? translate("Passed") : translate("Failed")
    const entry = (ENUMS?.employee_exam_appointment?.workflow_statuses || []).find(item => item.value === attempt.workflow_status)
    return entry ? translate(entry.name) : attempt.workflow_status
  }

  attemptStatusClasses(attempt) {
    if (attempt.workflow_status === "graded") {
      return attempt.passed ? "bg-success/10 text-success" : "bg-danger/10 text-danger"
    }
    switch (attempt.workflow_status) {
      case "in_progress": return "bg-warning/10 text-warning"
      case "submitted": return "bg-primary/10 text-primary"
      case "expired": return "bg-warning/10 text-warning"
      default: return "bg-muted text-muted-foreground"
    }
  }

  actionHTML() {
    const companyId = currentCompany()?.id

    if (this.inProgressAppointmentId) {
      return `
        <a href="${Helpers.take_company_my_exam_appointment_path(companyId, this.inProgressAppointmentId)}"
          class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
          <span class="material-symbols-outlined text-[18px]!">play_arrow</span>${translate("Resume Exam")}
        </a>
      `
    }

    if (this.canStart) {
      const label = this.attempts.some(attempt => ["graded", "expired"].includes(attempt.workflow_status))
        ? translate("Retake")
        : translate("Start Exam")
      return `
        <button type="button" data-action="click->${this.identifier}#startExam"
          class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
          <span class="material-symbols-outlined text-[18px]!">play_arrow</span>${label}
        </button>
      `
    }

    return ""
  }

  attemptsHTML() {
    if (this.attempts.length === 0) {
      return `<p class="p-4 text-sm text-muted-foreground">${translate("No attempts yet.")}</p>`
    }

    return `
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-left">
          <thead>
            <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
              <th class="px-4 py-3 text-center font-medium">${translate("Attempt")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Status")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Score")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Submitted")}</th>
              <th class="px-4 py-3 text-right font-medium">${translate("Actions")}</th>
            </tr>
          </thead>
          <tbody>
            ${this.attempts.map(attempt => `
              <tr class="border-b border-line/70">
                <td class="px-4 py-3 text-center text-sm text-muted-foreground">#${attempt.attempt_number}</td>
                <td class="px-4 py-3 text-center">
                  <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.attemptStatusClasses(attempt)}">
                    ${this.attemptStatusLabel(attempt)}
                  </span>
                </td>
                <td class="px-4 py-3 text-center text-sm text-foreground">${attempt.score === null || attempt.score === undefined ? "—" : Number(attempt.score).toFixed(2)}</td>
                <td class="px-4 py-3 text-center text-xs text-muted-foreground">${attempt.submitted_at ? Helpers.timeFormat(attempt.submitted_at) : "—"}</td>
                <td class="px-4 py-3 text-right">
                  ${["graded", "expired", "submitted"].includes(attempt.workflow_status)
                    ? `<a href="${Helpers.company_my_exam_appointment_path(currentCompany()?.id, attempt.id)}"
                         class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-primary hover:bg-primary/10">
                         ${translate("View Result")}
                       </a>`
                    : ""
                  }
                </td>
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
    const bestScore = this.attempts
      .filter(attempt => attempt.workflow_status === "graded")
      .map(attempt => attempt.score)
      .filter(score => score !== null && score !== undefined)
      .sort((a, b) => Number(b) - Number(a))[0]
    const attemptsLabel = this.maxAttempts === null || this.maxAttempts === undefined
      ? `${this.attemptsUsed} / ∞`
      : `${this.attemptsUsed} / ${this.maxAttempts}`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-4xl space-y-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 class="text-xl font-bold text-foreground">${escapeHtml(exam.name)}</h2>
              <p class="mt-1 max-w-3xl text-sm text-muted-foreground">${escapeHtml(exam.description || "")}</p>
            </div>
            <div class="flex items-center gap-2">
              <a href="${Helpers.company_my_exams_path(companyId)}"
                class="rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted">${translate("Back")}</a>
              ${this.actionHTML()}
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Questions")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${exam.questions_count}</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Duration")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${exam.duration_minutes ? `${exam.duration_minutes} ${translate("min")}` : translate("No time limit")}</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Pass mark")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${Number(exam.passing_score).toFixed(2)}%</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Attempts")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${attemptsLabel}</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Best Score")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${bestScore === undefined ? "—" : Number(bestScore).toFixed(2)}</p>
            </div>
          </div>

          <div class="rounded-xl border border-line bg-card">
            <div class="border-b border-line px-4 py-3">
              <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Attempt History")}</h3>
            </div>
            ${this.attemptsHTML()}
          </div>
        </div>
      </div>
    `
  }

  async startExam() {
    try {
      const response = await fetchJson(Helpers.start_company_my_exam_path(currentCompany()?.id, this.exam.id), { method: "POST" })
      navigateThenToast(response.redirect_url, { type: "success", message: response.message })
    } catch (error) {
      if (error.redirect_url) {
        navigateThenToast(error.redirect_url, { type: "error", message: error.errors?.join(", ") || error.message })
      } else {
        toast({ type: "error", message: error.errors?.join(", ") || error.message })
      }
    }
  }
}

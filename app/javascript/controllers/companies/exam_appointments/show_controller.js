import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ExamAppointments_ShowController extends Companies_LayoutController {
  // Manager attempt detail + text grading.
  // Depends on BE: Companies::ExamAppointmentsController#show/#grade
  // Endpoints: GET /companies/:id/exams/:exam_id/appointments/:id.json,
  //            PATCH .../appointments/:id/grade
  // Docs: docs/EXAMS.md

  exam = null
  appointment = null
  answers = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exam = response.exam
      this.appointment = response.appointment
      this.answers = response.appointment?.answers || []

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load attempt")}${detail ? ": " + detail : ""}` })
    }
  }

  statusLabel() {
    if (this.appointment?.status === "graded") return this.appointment.passed ? translate("Passed") : translate("Failed")
    const entry = (ENUMS?.employee_exam_appointment?.workflow_statuses || []).find(item => item.value === this.appointment?.status)
    return entry ? translate(entry.name) : this.appointment?.status
  }

  statusClasses() {
    if (this.appointment?.status === "graded") {
      return this.appointment.passed ? "bg-success/10 text-success" : "bg-danger/10 text-danger"
    }
    if (this.appointment?.status === "submitted") return "bg-primary/10 text-primary"
    if (this.appointment?.status === "expired") return "bg-warning/10 text-warning"
    return "bg-muted text-muted-foreground"
  }

  formatScore(value) {
    return value === null || value === undefined ? "—" : Number(value).toFixed(2)
  }

  optionsHTML(answer) {
    if (answer.question_type === "text") {
      return `
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div class="rounded-lg border border-line bg-background p-3">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Employee Answer")}</p>
            <p class="mt-1 whitespace-pre-wrap text-sm text-foreground">${escapeHtml(answer.text_answer || "—")}</p>
          </div>
          <div class="rounded-lg border border-line bg-background p-3">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Model Answer")}</p>
            <p class="mt-1 whitespace-pre-wrap text-sm text-foreground">${escapeHtml(answer.question?.correct_text || "—")}</p>
          </div>
        </div>
      `
    }

    return `
      <div class="space-y-2">
        ${(answer.question?.options || []).map((option, index) => {
          const selected = (answer.selected_option_ids || []).map(String).includes(String(option.id))
          return `
            <div class="flex items-center gap-3 rounded-lg border ${option.correct ? "border-success/40 bg-success/10" : selected ? "border-primary/40 bg-primary/10" : "border-line bg-card"} p-3">
              <span class="flex h-7 w-7 items-center justify-center rounded-full bg-muted text-xs font-bold text-foreground">${String.fromCharCode(65 + index)}</span>
              <span class="flex-1 text-sm text-foreground">${escapeHtml(option.content)}</span>
              ${option.correct ? `<span class="text-xs font-bold text-success">${translate("Correct")}</span>` : ""}
              ${selected ? `<span class="text-xs font-bold text-primary">${translate("Selected")}</span>` : ""}
            </div>
          `
        }).join("")}
      </div>
    `
  }

  answerHTML(answer) {
    const canGrade = this.appointment.can_grade && answer.question_type === "text"

    return `
      <div class="rounded-xl border border-line bg-card p-4">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground">${translate("Question")} ${answer.position + 1}</p>
            <p class="mt-1 text-sm font-medium text-foreground">${escapeHtml(answer.question?.name || "")}</p>
            ${answer.question?.description ? `<p class="mt-1 text-xs text-muted-foreground">${escapeHtml(answer.question.description)}</p>` : ""}
          </div>
          ${answer.correct === null || answer.correct === undefined ? "" : `
            <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${answer.correct ? "bg-success/10 text-success" : "bg-danger/10 text-danger"}">
              ${answer.correct ? translate("Correct") : translate("Incorrect")}
            </span>
          `}
        </div>

        <div class="mt-3">${this.optionsHTML(answer)}</div>

        <div class="mt-3 flex flex-wrap items-center justify-between gap-3 border-t border-line pt-3">
          <p class="text-xs text-muted-foreground">
            ${translate("Points")}: ${this.formatScore(answer.points_awarded)} / ${this.formatScore(answer.points_possible)}
          </p>
          ${canGrade ? `
            <label class="flex items-center gap-2 text-xs font-medium text-muted-foreground">
              ${translate("Award points")}
              <input type="number" data-grade-input data-answer-id="${answer.id}"
                min="0" max="${answer.points_possible}" step="0.01" value="${answer.points_awarded || 0}"
                class="w-24 rounded-lg border border-line bg-background px-2 py-1 text-sm text-foreground">
            </label>
          ` : ""}
        </div>
      </div>
    `
  }

  contentHTML() {
    const appointment = this.appointment
    if (!appointment) return `<div class="p-8 text-center text-muted-foreground">${translate("Attempt not found.")}</div>`

    const companyId = currentCompany()?.id
    const exam = this.exam

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-4xl space-y-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <a href="${Helpers.company_exam_appointments_path(companyId, exam.id)}"
                class="mb-1 inline-flex items-center gap-1 text-xs font-medium text-muted-foreground hover:text-primary">
                <span class="material-symbols-outlined text-[16px]!">arrow_back</span>${translate("Attempts")}
              </a>
              <h2 class="text-xl font-bold text-foreground">${escapeHtml(appointment.employee?.name || "—")}</h2>
              <p class="text-sm text-muted-foreground">${escapeHtml(exam.name)} · ${translate("Attempt")} #${appointment.attempt_number}</p>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses()}">${this.statusLabel()}</span>
              ${appointment.can_grade ? `
                <button type="button" data-action="click->${this.identifier}#saveGrades"
                  class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
                  <span class="material-symbols-outlined text-[18px]!">save</span>${translate("Save Grades")}
                </button>
              ` : ""}
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Score")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${this.formatScore(appointment.score)}</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Pass mark")}</p>
              <p class="mt-1 text-lg font-bold text-foreground">${this.formatScore(exam.passing_score)}%</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Submitted")}</p>
              <p class="mt-1 text-sm font-medium text-foreground">${appointment.submitted_at ? Helpers.timeFormat(appointment.submitted_at) : "—"}</p>
            </div>
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Graded")}</p>
              <p class="mt-1 text-sm font-medium text-foreground">${appointment.graded_at ? Helpers.timeFormat(appointment.graded_at) : "—"}</p>
            </div>
          </div>

          <div class="space-y-3">
            ${this.answers.map(answer => this.answerHTML(answer)).join("")}
          </div>
        </div>
      </div>
    `
  }

  async saveGrades() {
    const grades = {}
    this.element.querySelectorAll("[data-grade-input]").forEach(input => {
      grades[input.dataset.answerId] = input.value
    })

    try {
      const response = await fetchJson(Helpers.grade_company_exam_appointment_path(currentCompany()?.id, this.exam.id, this.appointment.id), {
        method: "PATCH",
        body: { grades }
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }
}

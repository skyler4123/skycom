import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_MyExamAppointments_ShowController extends Companies_LayoutController {
  // Attempt result + per-question review.
  // Depends on BE: Companies::MyExamAppointmentsController#show
  // Endpoints: GET /companies/:id/my_exam_appointments/:id.json
  // Docs: docs/EXAMS.md

  appointment = null
  exam = null
  answers = []
  canRetake = false

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()

      if (response.redirect_url) {
        window.location.href = response.redirect_url
        return
      }

      this.appointment = response.appointment
      this.exam = response.exam
      this.answers = response.answers || []
      this.canRetake = response.can_retake

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load result")}${detail ? ": " + detail : ""}` })
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

  answerReviewHTML(answer) {
    const selected = (answer.selected_options || []).map(option => option.content).join(", ")
    const correctOptions = (answer.question?.options || []).filter(option => option.correct).map(option => option.content)
    const pending = this.appointment.status === "submitted"
    const isText = answer.question_type === "text"
    const correctAnswer = isText ? (answer.question?.correct_text || "—") : (correctOptions.join(", ") || "—")

    return `
      <div class="rounded-xl border border-line bg-card p-4">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground">
              ${translate("Question")} ${answer.position + 1}
            </p>
            <p class="mt-1 text-sm font-medium text-foreground">${escapeHtml(answer.question?.name || "")}</p>
            ${answer.question?.description ? `<p class="mt-1 text-xs text-muted-foreground">${escapeHtml(answer.question.description)}</p>` : ""}
          </div>
          ${!pending ? `
            <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${answer.correct ? "bg-success/10 text-success" : "bg-danger/10 text-danger"}">
              ${answer.correct ? translate("Correct") : translate("Incorrect")}
            </span>
          ` : ""}
        </div>

        <div class="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div class="rounded-lg border border-line bg-background p-3">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Your Answer")}</p>
            <p class="mt-1 whitespace-pre-wrap text-sm text-foreground">${escapeHtml(isText ? (answer.text_answer || "—") : (selected || "—"))}</p>
          </div>
          ${!pending ? `
            <div class="rounded-lg border border-line bg-background p-3">
              <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Correct Answer")}</p>
              <p class="mt-1 whitespace-pre-wrap text-sm text-foreground">${escapeHtml(correctAnswer)}</p>
            </div>
          ` : ""}
        </div>

        ${!pending ? `
          <p class="mt-2 text-xs text-muted-foreground">
            ${translate("Points")}: ${this.formatScore(answer.points_awarded)} / ${this.formatScore(answer.points_possible)}
          </p>
        ` : ""}
      </div>
    `
  }

  contentHTML() {
    const appointment = this.appointment
    if (!appointment) return `<div class="p-8 text-center text-muted-foreground">${translate("Result not found.")}</div>`

    const companyId = currentCompany()?.id
    const pending = appointment.status === "submitted"
    const passed = appointment.passed === true

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-4xl space-y-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <div class="mb-2 flex flex-wrap items-center gap-2">
                <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.statusClasses()}">
                  ${this.statusLabel()}
                </span>
                <span class="text-xs text-muted-foreground">${translate("Attempt")} #${appointment.attempt_number}</span>
                ${appointment.submitted_at ? `<span class="text-xs text-muted-foreground">${translate("Submitted")}: ${Helpers.timeFormat(appointment.submitted_at)}</span>` : ""}
              </div>
              <h2 class="text-xl font-bold text-foreground">${escapeHtml(this.exam?.name || "")}</h2>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              <a href="${Helpers.company_my_exams_path(companyId)}"
                class="rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted">${translate("My Exams")}</a>
              ${this.canRetake ? `
                <button type="button" data-action="click->${this.identifier}#retakeExam"
                  class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
                  <span class="material-symbols-outlined text-[18px]!">replay</span>${translate("Retake")}
                </button>
              ` : ""}
            </div>
          </div>

          ${pending ? `
            <div class="rounded-xl border border-primary/40 bg-primary/10 p-4">
              <p class="text-sm font-bold text-primary">${translate("Pending review")}</p>
              <p class="mt-1 text-sm text-primary">${translate("Your text answers are waiting for a manager to grade them.")}</p>
            </div>
          ` : `
            <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
              <div class="rounded-xl border border-line bg-card p-3">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Score")}</p>
                <p class="mt-1 text-lg font-bold ${passed ? "text-success" : "text-danger"}">${this.formatScore(appointment.score)}</p>
              </div>
              <div class="rounded-xl border border-line bg-card p-3">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Result")}</p>
                <p class="mt-1 text-lg font-bold ${passed ? "text-success" : "text-danger"}">${passed ? translate("Passed") : translate("Failed")}</p>
              </div>
              <div class="rounded-xl border border-line bg-card p-3">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Pass mark")}</p>
                <p class="mt-1 text-lg font-bold text-foreground">${this.formatScore(this.exam?.passing_score)}%</p>
              </div>
              <div class="rounded-xl border border-line bg-card p-3">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Attempt")}</p>
                <p class="mt-1 text-lg font-bold text-foreground">#${appointment.attempt_number}</p>
              </div>
            </div>
          `}

          <div class="space-y-3">
            ${this.answers.map(answer => this.answerReviewHTML(answer)).join("")}
          </div>
        </div>
      </div>
    `
  }

  async retakeExam() {
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

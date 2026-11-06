import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_MyExams_IndexController extends Companies_LayoutController {
  // Employee exam center: To Do / In Progress / History.
  // Depends on BE: Companies::MyExamsController#index + #start
  // Endpoints: GET /companies/:id/my_exams.json,
  //            POST /companies/:id/my_exams/:id/start
  // Docs: docs/EXAMS.md

  /** @type {Array} */
  exams = []
  activeTab = "todo"

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.exams = response.exams || []

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load my exams")}${detail ? ": " + detail : ""}` })
    }
  }

  latestAttempt(exam) {
    return exam.latest_appointment || exam.attempts?.[exam.attempts.length - 1] || null
  }

  hasCompletedAttempt(exam) {
    return (exam.attempts || []).some(attempt => ["graded", "expired"].includes(attempt.workflow_status))
  }

  pendingReview(exam) {
    return (exam.attempts || []).some(attempt => attempt.workflow_status === "submitted")
  }

  todoExams() {
    return this.exams.filter(exam => exam.can_start && !exam.in_progress_appointment_id && !this.pendingReview(exam))
  }

  inProgressExams() {
    return this.exams.filter(exam => exam.in_progress_appointment_id || this.pendingReview(exam))
  }

  historyExams() {
    return this.exams.filter(exam => this.hasCompletedAttempt(exam))
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

  examActionHTML(exam) {
    if (exam.in_progress_appointment_id) {
      return `
        <a href="${Helpers.take_company_my_exam_appointment_path(currentCompany()?.id, exam.in_progress_appointment_id)}"
          class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
          <span class="material-symbols-outlined text-[18px]!">play_arrow</span>${translate("Resume Exam")}
        </a>
      `
    }

    if (this.pendingReview(exam)) {
      const pending = this.latestAttempt(exam)
      if (pending) {
        return `
          <a href="${Helpers.company_my_exam_appointment_path(currentCompany()?.id, pending.id)}"
            class="inline-flex items-center gap-1.5 rounded-lg border border-line px-4 py-2 text-sm font-medium text-foreground hover:bg-muted">
            <span class="material-symbols-outlined text-[18px]!">visibility</span>${translate("View Result")}
          </a>
        `
      }
    }

    if (exam.can_start) {
      const label = this.hasCompletedAttempt(exam) ? translate("Retake") : translate("Start Exam")
      return `
        <button type="button" data-action="click->${this.identifier}#startExam" data-exam-id="${exam.id}"
          class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
          <span class="material-symbols-outlined text-[18px]!">play_arrow</span>${label}
        </button>
      `
    }

    const latest = this.latestAttempt(exam)
    if (latest) {
      return `
        <a href="${Helpers.company_my_exam_appointment_path(currentCompany()?.id, latest.id)}"
          class="inline-flex items-center gap-1.5 rounded-lg border border-line px-4 py-2 text-sm font-medium text-foreground hover:bg-muted">
          <span class="material-symbols-outlined text-[18px]!">visibility</span>${translate("View Result")}
        </a>
      `
    }

    return ""
  }

  examCardHTML(exam) {
    const latest = this.latestAttempt(exam)
    const bestScore = exam.best_score === null || exam.best_score === undefined ? null : Number(exam.best_score).toFixed(2)
    const attemptsLabel = exam.max_attempts === null || exam.max_attempts === undefined
      ? `${exam.attempts_used} / ∞`
      : `${exam.attempts_used} / ${exam.max_attempts}`

    return `
      <div class="rounded-xl border border-line bg-card p-4">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <div class="mb-2 flex flex-wrap items-center gap-2">
              ${latest ? `
                <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.attemptStatusClasses(latest)}">
                  ${this.attemptStatusLabel(latest)}
                </span>
              ` : ""}
              <span class="text-xs text-muted-foreground">${exam.questions_count} ${translate("questions")}</span>
              <span class="text-xs text-muted-foreground">${exam.duration_minutes ? `${exam.duration_minutes} ${translate("min")}` : translate("No time limit")}</span>
              <span class="text-xs text-muted-foreground">${translate("Pass mark")}: ${Number(exam.passing_score).toFixed(2)}%</span>
            </div>
            <a href="${Helpers.company_my_exam_path(currentCompany()?.id, exam.id)}"
              class="text-base font-bold text-foreground hover:text-primary">${escapeHtml(exam.name)}</a>
            <p class="mt-1 line-clamp-2 text-sm text-muted-foreground">${escapeHtml(exam.description || "")}</p>
          </div>
          <div class="flex shrink-0 flex-col items-start gap-2 sm:items-end">
            ${this.examActionHTML(exam)}
            <div class="flex gap-3 text-xs text-muted-foreground">
              <span>${translate("Attempts")}: ${attemptsLabel}</span>
              <span>${translate("Best Score")}: ${bestScore === null ? "—" : bestScore}</span>
            </div>
          </div>
        </div>
      </div>
    `
  }

  historyTableHTML() {
    const rows = this.historyExams().flatMap(exam =>
      (exam.attempts || [])
        .filter(attempt => ["graded", "expired", "submitted"].includes(attempt.workflow_status))
        .map(attempt => ({ exam, attempt }))
    )

    if (rows.length === 0) {
      return `<p class="p-6 text-sm text-muted-foreground">${translate("No exam history yet.")}</p>`
    }

    return `
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-left">
          <thead>
            <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
              <th class="px-4 py-3 font-medium">${translate("Exam")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Attempt")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Status")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Score")}</th>
              <th class="px-4 py-3 text-center font-medium">${translate("Submitted")}</th>
              <th class="px-4 py-3 text-right font-medium">${translate("Actions")}</th>
            </tr>
          </thead>
          <tbody>
            ${rows.map(({ exam, attempt }) => `
              <tr class="border-b border-line/70">
                <td class="px-4 py-3 text-sm text-foreground">${escapeHtml(exam.name)}</td>
                <td class="px-4 py-3 text-center text-sm text-muted-foreground">#${attempt.attempt_number}</td>
                <td class="px-4 py-3 text-center">
                  <span class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${this.attemptStatusClasses(attempt)}">
                    ${this.attemptStatusLabel(attempt)}
                  </span>
                </td>
                <td class="px-4 py-3 text-center text-sm text-foreground">${attempt.score === null || attempt.score === undefined ? "—" : Number(attempt.score).toFixed(2)}</td>
                <td class="px-4 py-3 text-center text-xs text-muted-foreground">${attempt.submitted_at ? Helpers.timeFormat(attempt.submitted_at) : "—"}</td>
                <td class="px-4 py-3 text-right">
                  <a href="${Helpers.company_my_exam_appointment_path(currentCompany()?.id, attempt.id)}"
                    class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-primary hover:bg-primary/10">
                    ${translate("View Result")}
                  </a>
                </td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  tabButtonHTML(key, label, count) {
    const active = this.activeTab === key
    return `
      <button type="button" data-action="click->${this.identifier}#switchTab" data-tab="${key}"
        class="inline-flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium ${active ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted hover:text-foreground"}">
        ${label}
        <span class="rounded-full ${active ? "bg-primary-foreground/20" : "bg-muted"} px-2 py-0.5 text-xs">${count}</span>
      </button>
    `
  }

  contentHTML() {
    const todo = this.todoExams()
    const inProgress = this.inProgressExams()
    const history = this.historyExams()

    let body = ""
    if (this.activeTab === "history") {
      body = this.historyTableHTML()
    } else {
      const exams = this.activeTab === "in_progress" ? inProgress : todo
      body = exams.length === 0
        ? `<p class="p-6 text-sm text-muted-foreground">${this.activeTab === "in_progress" ? translate("No exams in progress.") : translate("No exams to do right now.")}</p>`
        : `<div class="space-y-3">${exams.map(exam => this.examCardHTML(exam)).join("")}</div>`
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-5xl space-y-4">
          <div>
            <h2 class="text-xl font-bold text-foreground">${translate("My Exams")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Assigned exams, attempts in progress, and your results.")}</p>
          </div>

          <div class="flex flex-wrap items-center gap-2 rounded-xl border border-line bg-card p-2">
            ${this.tabButtonHTML("todo", translate("To Do"), todo.length)}
            ${this.tabButtonHTML("in_progress", translate("In Progress"), inProgress.length)}
            ${this.tabButtonHTML("history", translate("History"), history.length)}
          </div>

          <div class="rounded-xl border border-line bg-card p-4">
            ${body}
          </div>
        </div>
      </div>
    `
  }

  switchTab(event) {
    this.activeTab = event.currentTarget.dataset.tab
    this.renderContent()
  }

  async startExam(event) {
    const examId = event.currentTarget.dataset.examId
    try {
      const response = await fetchJson(Helpers.start_company_my_exam_path(currentCompany()?.id, examId), { method: "POST" })
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
